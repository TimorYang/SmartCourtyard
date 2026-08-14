import Flutter
import Foundation
import AVFoundation
import CoreLocation
import Photos
import UIKit

#warning("FLINX-SAFETY-DOOR-SENSOR-NAME: 0x01 暂命名为“无线门磁”，发布前请确认最终产品文案与切图。")

final class HardwareBridge: HardwareHostApi {
    private let bleManager: BleManager
    private let logger: BleLogger
    private let flutterApi: HardwareFlutterApi
    private var provisioningReadiness: [String: Bool] = [:]
    private var provisioningBuffers: [String: Data] = [:]
    private var provisioningAesKeys: [String: Data] = [:]
    private var pendingProvisioningRequests: [String: PendingProvisioningRequest] = [:]
    private var pendingAttributeQueries: [String: PendingAttributeQuery] = [:]
    private var provisioningSequences: [String: UInt16] = [:]
    private var flutterConsoleLoggingEnabled = false
    private var pendingDiagnostics: [String: PendingBleDiagnostic] = [:]
    private var permissionLocationManager: CLLocationManager?
    
    init(binaryMessenger: FlutterBinaryMessenger) {
        self.logger = BleLogger()
        self.bleManager = BleManager(logger: logger)
        self.flutterApi = HardwareFlutterApi(binaryMessenger: binaryMessenger)
        self.bleManager.delegate = self
    }

    func configureHardwareLogging(
        flutterConsoleEnabled: Bool,
        nativeConsoleEnabled: Bool
    ) throws {
        flutterConsoleLoggingEnabled = flutterConsoleEnabled
        logger.setNativeConsoleLogging(enabled: nativeConsoleEnabled)
    }
    
    func getPermissionSnapshot(requestId: String) throws -> PermissionSnapshotDto {
        PermissionSnapshotDto(
            bluetoothStatus: bleManager.bluetoothGranted() ? .granted : .blocked,
            cameraStatus: cameraPermissionStatus(),
            locationStatus: locationPermissionStatus(),
            microphoneStatus: microphonePermissionStatus(),
            storageStatus: storagePermissionStatus(),
            localNetworkGranted: false,
            notificationGranted: false
        )
    }
    
    func requestPermissions(
        requestId: String,
        permissions: [PermissionKindDto]
    ) throws -> PermissionSnapshotDto {
        if permissions.contains(.bluetooth) {
            bleManager.prepareForPermissionRequest()
        }
        if permissions.contains(.camera) {
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        }
        if permissions.contains(.microphone) {
            AVAudioSession.sharedInstance().requestRecordPermission { _ in }
        }
        if permissions.contains(.storage) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in }
        }
        if permissions.contains(.location) {
            let manager = CLLocationManager()
            permissionLocationManager = manager
            manager.requestWhenInUseAuthorization()
        }
        return try getPermissionSnapshot(requestId: requestId)
    }

    func openAppSettings(requestId: String) throws {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func cameraPermissionStatus() -> PermissionStatusDto {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .granted
        case .notDetermined: return .denied
        case .denied, .restricted: return .blocked
        @unknown default: return .blocked
        }
    }

    private func locationPermissionStatus() -> PermissionStatusDto {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse: return .granted
        case .notDetermined: return .denied
        case .denied, .restricted: return .blocked
        @unknown default: return .blocked
        }
    }

    private func microphonePermissionStatus() -> PermissionStatusDto {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted: return .granted
        case .undetermined: return .denied
        case .denied: return .blocked
        @unknown default: return .blocked
        }
    }

    private func storagePermissionStatus() -> PermissionStatusDto {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited: return .granted
        case .notDetermined: return .denied
        case .denied, .restricted: return .blocked
        @unknown default: return .blocked
        }
    }
    
    func startBleScan(requestId: String, filter: BleScanFilterDto) throws {
        try bleManager.startScan(requestId: requestId, filter: filter.toNative())
    }
    
    func stopBleScan(requestId: String) throws {
        bleManager.stopScan(requestId: requestId)
    }

    func getConnectedBleDevices(
        requestId: String,
        completion: @escaping (Result<[ConnectedBleDeviceDto], Error>) -> Void
    ) {
        completion(
            .success(
                bleManager.connectedManagedDevices().map {
                    ConnectedBleDeviceDto(
                        deviceId: $0.deviceId,
                        name: $0.name,
                        state: $0.state.toDto()
                    )
                }
            )
        )
    }

    func disconnectAllManagedBleDevices(
        requestId: String,
        completion: @escaping (Result<[BleConnectionEventDto], Error>) -> Void
    ) {
        bleManager.disconnectAllManaged(requestId: requestId) { events in
            completion(.success(events.map { $0.toDto() }))
        }
    }
    
    func connectBleDevice(
        requestId: String,
        deviceId: String,
        completion: @escaping (Result<BleConnectionEventDto, Error>) -> Void
    ) {
        bleManager.connect(requestId: requestId, deviceId: deviceId) { result in
            completion(result.map { $0.toDto() }.mapError(Self.toPigeonError))
        }
    }
    
    func authenticateBleDevice(
        requestId: String,
        deviceId: String,
        token: String,
        aesKey: String,
        aesKeyVersion: String,
        completion: @escaping (Result<BleAuthenticationResultDto, Error>) -> Void
    ) {
        logger.info(
            "ble_authenticate",
            requestId: requestId,
            deviceId: deviceId,
            state: "started",
            details: "onboardingFlowId=\(Self.flowId(from: requestId)) aesKeySource=server aesKeyVersion=\(aesKeyVersion)"
        )
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedToken.count == 32,
              let tokenBytes = Data(hexString: normalizedToken),
              tokenBytes.count == kCCKeySizeAES128 else {
            logger.warning(
                "ble_authenticate",
                requestId: requestId,
                deviceId: deviceId,
                state: "rejected",
                nativeCode: "invalid_auth_token",
                details: "tokenLength=\(normalizedToken.count)"
            )
            completion(
                .failure(
                    PigeonError(
                        code: "invalid_auth_token",
                        message: "BLE auth token must be a 32-character hex MD5 string.",
                        details: nil
                    )
                )
            )
            return
        }

        let normalizedAesKey = aesKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedAesKey.count == 32,
              let aesKeyBytes = Data(hexString: normalizedAesKey),
              aesKeyBytes.count == kCCKeySizeAES128 else {
            completion(
                .failure(
                    PigeonError(
                        code: "invalid_aes_key",
                        message: "BLE AES key must be a 32-character hexadecimal string.",
                        details: nil
                    )
                )
            )
            return
        }
        provisioningAesKeys[deviceId] = aesKeyBytes
        
        ensureProvisioningChannel(requestId: requestId, deviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(Self.toPigeonError(error)))
            case .success:
                let utcSeconds = UInt32(Date().timeIntervalSince1970)
                var payload = Data()
                payload.append(contentsOf: Self.bigEndianBytes(utcSeconds))
                payload.append(tokenBytes)
                self.sendProvisioningRequest(
                    requestId: requestId,
                    deviceId: deviceId,
                    command: BleProvisioningCommand.authenticate,
                    payload: payload
                ) { response in
                    guard response.data.count >= 1 else {
                        completion(
                            .failure(
                                PigeonError(
                                    code: "invalid_auth_response",
                                    message: "BLE auth response is empty.",
                                    details: nil
                                )
                            )
                        )
                        return
                    }
                    
                    let resultCode = response.data[0]
                    let bindingState = response.data.count > 1 ? Int64(response.data[1]) : nil
                    self.logger.info(
                        "ble_authenticate",
                        requestId: requestId,
                        deviceId: deviceId,
                        state: resultCode == 0x00 ? "success" : "failed",
                        nativeCode: resultCode == 0x00 ? nil : "auth_failed_\(resultCode)",
                        payloadBytes: response.data.count,
                        details: "bindingState=\(bindingState.map(String.init) ?? "none")"
                    )
                    completion(
                        .success(
                            BleAuthenticationResultDto(
                                requestId: requestId,
                                deviceId: deviceId,
                                authenticated: resultCode == 0x00,
                                bindingState: bindingState,
                                nativeCode: resultCode == 0x00 ? nil : "auth_failed_\(resultCode)"
                            )
                        )
                    )
                } failure: { error in
                    completion(.failure(Self.toPigeonError(error)))
                }
            }
        }
    }
    
    func scanWifiNetworks(
        requestId: String,
        deviceId: String,
        completion: @escaping (Result<WifiScanResultDto, Error>) -> Void
    ) {
        logger.info(
            "wifi_scan",
            requestId: requestId,
            deviceId: deviceId,
            state: "started",
            details: "command=\(BleProvisioningCommand.scanWifi.hexCode)"
        )
        ensureProvisioningChannel(requestId: requestId, deviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(Self.toPigeonError(error)))
            case .success:
                self.sendProvisioningRequest(
                    requestId: requestId,
                    deviceId: deviceId,
                    command: BleProvisioningCommand.scanWifi,
                    payload: Data()
                ) { response in
                    do {
                        let ssids = try Self.parseWifiList(from: response.data)
                        completion(
                            .success(
                                WifiScanResultDto(
                                    requestId: requestId,
                                    deviceId: deviceId,
                                    ssids: ssids
                                )
                            )
                        )
                    } catch {
                        completion(.failure(Self.toPigeonError(error)))
                    }
                } failure: { error in
                    completion(.failure(Self.toPigeonError(error)))
                }
            }
        }
    }
    
    func configureWifi(
        requestId: String,
        deviceId: String,
        ssid: String,
        password: String,
        completion: @escaping (Result<WifiProvisionResultDto, Error>) -> Void
    ) {
        ensureProvisioningChannel(requestId: requestId, deviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(Self.toPigeonError(error)))
            case .success:
                do {
                    let payload = try Self.makeWifiProvisionPayload(ssid: ssid, password: password)
                    self.sendProvisioningRequest(
                        requestId: requestId,
                        deviceId: deviceId,
                        command: BleProvisioningCommand.configureWifi,
                        payload: payload
                    ) { response in
                        guard response.data.count >= 1 else {
                            completion(
                                .failure(
                                    PigeonError(
                                        code: "invalid_wifi_provision_response",
                                        message: "BLE wifi provision response is empty.",
                                        details: nil
                                    )
                                )
                            )
                            return
                        }
                        
                        let resultCode = response.data[0]
                        completion(
                            .success(
                                WifiProvisionResultDto(
                                    requestId: requestId,
                                    deviceId: deviceId,
                                    ssid: ssid,
                                    success: resultCode == 0x00,
                                    nativeCode: resultCode == 0x00 ? nil : "wifi_provision_failed_\(resultCode)"
                                )
                            )
                        )
                    } failure: { error in
                        completion(.failure(Self.toPigeonError(error)))
                    }
                } catch {
                    completion(.failure(Self.toPigeonError(error)))
                }
            }
        }
    }
    
    func disconnectBleDevice(
        requestId: String,
        deviceId: String,
        completion: @escaping (Result<BleConnectionEventDto, Error>) -> Void
    ) {
        bleManager.disconnect(requestId: requestId, deviceId: deviceId) { result in
            completion(result.map { $0.toDto() }.mapError(Self.toPigeonError))
        }
    }
    
    func discoverServices(
        requestId: String,
        deviceId: String,
        completion: @escaping (Result<BleServicesDto, Error>) -> Void
    ) {
        bleManager.discoverServices(requestId: requestId, deviceId: deviceId) { result in
            completion(result.map { $0.toDto() }.mapError(Self.toPigeonError))
        }
    }
    
    func readCharacteristic(
        requestId: String,
        deviceId: String,
        serviceUuid: String,
        characteristicUuid: String,
        completion: @escaping (Result<BleReadResultDto, Error>) -> Void
    ) {
        bleManager.readCharacteristic(
            requestId: requestId,
            deviceId: deviceId,
            serviceUuid: serviceUuid,
            characteristicUuid: characteristicUuid
        ) { result in
            completion(result.map { $0.toDto() }.mapError(Self.toPigeonError))
        }
    }
    
    func writeCharacteristic(
        requestId: String,
        deviceId: String,
        serviceUuid: String,
        characteristicUuid: String,
        payload: FlutterStandardTypedData,
        writeType: BleWriteTypeDto,
        completion: @escaping (Result<BleWriteResultDto, Error>) -> Void
    ) {
        bleManager.writeCharacteristic(
            requestId: requestId,
            deviceId: deviceId,
            serviceUuid: serviceUuid,
            characteristicUuid: characteristicUuid,
            payload: payload.data,
            writeType: writeType.toNative()
        ) { result in
            completion(result.map { $0.toDto() }.mapError(Self.toPigeonError))
        }
    }
    
    func setCharacteristicNotify(
        requestId: String,
        deviceId: String,
        serviceUuid: String,
        characteristicUuid: String,
        enabled: Bool,
        completion: @escaping (Result<BleWriteResultDto, Error>) -> Void
    ) {
        bleManager.setCharacteristicNotify(
            requestId: requestId,
            deviceId: deviceId,
            serviceUuid: serviceUuid,
            characteristicUuid: characteristicUuid,
            enabled: enabled
        ) { result in
            completion(result.map { $0.toDto() }.mapError(Self.toPigeonError))
        }
    }
    
    func sendDoorCommand(
        requestId: String,
        deviceId: String,
        command: DoorCommandDto,
        completion: @escaping (Result<CommandResultDto, Error>) -> Void
    ) {
        let control = command.doorControlCode
        let sequence = nextProvisioningSequence(for: deviceId)
        guard let aesKey = provisioningAesKeys[deviceId],
              let frame = Self.makeFrame(
            sequence: sequence,
            command: DoorControlCommand.commandControlDoor,
            payload: Data(Self.bigEndianBytes(control)),
            encrypted: true,
            aesKey: aesKey
        ) else {
            completion(
                .failure(
                    PigeonError(
                        code: "door_command_encrypt_failed",
                        message: "Failed to encrypt BLE door control request.",
                        details: nil
                    )
                )
            )
            return
        }

        logger.info(
            "door_command",
            requestId: requestId,
            deviceId: deviceId,
            state: "sending",
            payloadBytes: frame.count,
            details: "command=\(DoorControlCommand.hexCode) control=\(DoorControlCommand.hex(control)) sequence=\(DoorControlCommand.hex(sequence)) frame=\(logger.payloadHex(frame))"
        )
        emitTxDiagnostic(
            requestId: requestId,
            deviceId: deviceId,
            operation: command.displayName,
            command: DoorControlCommand.commandControlDoor,
            control: control,
            sequence: sequence,
            originPayload: Self.makeFrameData(
                sequence: sequence,
                command: DoorControlCommand.commandControlDoor,
                payload: Data(Self.bigEndianBytes(control))
            ),
            packet: frame,
            encrypted: true,
            sensitive: false
        )
        bleManager.writeCharacteristic(
            requestId: requestId,
            deviceId: deviceId,
            serviceUuid: BleProvisioningCommand.serviceUuid,
            characteristicUuid: BleProvisioningCommand.writeCharacteristicUuid,
            payload: frame,
            writeType: .withResponse
        ) { result in
            completion(
                result
                    .map { writeResult in
                        CommandResultDto(
                            requestId: requestId,
                            deviceId: deviceId,
                            accepted: writeResult.accepted,
                            nativeCode: "command=\(DoorControlCommand.hexCode),control=\(DoorControlCommand.hex(control)),sequence=\(DoorControlCommand.hex(sequence))",
                            domainCode: writeResult.accepted ? nil : "write_characteristic_failed"
                        )
                    }
                    .mapError(Self.toPigeonError)
            )
        }
    }

    func queryDeviceAttributes(
        requestId: String,
        deviceId: String,
        completion: @escaping (Result<DeviceAttributeSnapshotDto, Error>) -> Void
    ) {
        ensureProvisioningChannel(requestId: requestId, deviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(Self.toPigeonError(error)))
            case .success:
                self.sendAttributeQuery(
                    requestId: requestId,
                    deviceId: deviceId,
                    completion: completion
                )
            }
        }
    }

    func setDeviceAttributes(
        requestId: String,
        deviceId: String,
        attributes: [DeviceAttributeDto],
        completion: @escaping (Result<DeviceAttributeWriteResultDto, Error>) -> Void
    ) {
        let payload: Data
        do {
            payload = try Self.makeAttributeWritePayload(attributes)
        } catch {
            completion(.failure(Self.toPigeonError(error)))
            return
        }
        ensureProvisioningChannel(requestId: requestId, deviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(Self.toPigeonError(error)))
            case .success:
                self.sendProvisioningRequest(
                    requestId: requestId,
                    deviceId: deviceId,
                    command: .setAttributes,
                    payload: payload
                ) { frame in
                    guard let resultCode = frame.data.first else {
                        completion(
                            .failure(
                                PigeonError(
                                    code: "invalid_attribute_write_response",
                                    message: "Attribute write response is empty.",
                                    details: nil
                                )
                            )
                        )
                        return
                    }
                    let reasonCode = frame.data.count >= 5
                        ? Int64(Self.parseUInt32(frame.data.dropFirst().prefix(4).asData))
                        : nil
                    completion(
                        .success(
                            DeviceAttributeWriteResultDto(
                                requestId: requestId,
                                deviceId: deviceId,
                                success: resultCode == 0x01,
                                sequence: Int64(frame.sequence),
                                reasonCode: reasonCode
                            )
                        )
                    )
                } failure: { error in
                    completion(.failure(Self.toPigeonError(error)))
                }
            }
        }
    }

    func pairRemote(
        requestId: String,
        deviceId: String,
        action: RemotePairingActionDto,
        completion: @escaping (Result<RemotePairingResultDto, Error>) -> Void
    ) {
        let control = action.remotePairingControlCode
        if action == .cancel,
           let pending = pendingProvisioningRequests[deviceId],
           pending.command == .remotePairing {
            pending.timeout.cancel()
            pendingProvisioningRequests.removeValue(forKey: deviceId)
            pending.failure(
                PigeonError(
                    code: "remote_pairing_cancelled",
                    message: "Remote pairing was cancelled by the user.",
                    details: nil
                )
            )
            logger.info(
                "remote_pairing",
                requestId: pending.requestId,
                deviceId: deviceId,
                state: "cancelled"
            )
        }
        logger.info(
            "remote_pairing",
            requestId: requestId,
            deviceId: deviceId,
            state: "started",
            details: "command=\(BleProvisioningCommand.remotePairing.hexCode) control=\(DoorControlCommand.hex(control))"
        )

        ensureProvisioningChannel(requestId: requestId, deviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(Self.toPigeonError(error)))
            case .success:
                self.sendProvisioningRequest(
                    requestId: requestId,
                    deviceId: deviceId,
                    command: .remotePairing,
                    payload: Data(Self.bigEndianBytes(control)),
                    responseTimeout: RemotePairingProtocol.responseTimeout,
                    expectedResponseCommand: RemotePairingProtocol.responseCommand,
                    control: control
                ) { response in
                    guard response.data.count >= 1 else {
                        completion(
                            .failure(
                                PigeonError(
                                    code: "invalid_remote_pairing_response",
                                    message: "Remote pairing response is empty.",
                                    details: nil
                                )
                            )
                        )
                        return
                    }

                    let resultCode = response.data[0]
                    let status = RemotePairingStatusDto(resultCode: resultCode)
                    let reasonCode: UInt32 = status == .success
                        ? 0
                        : UInt32(resultCode)
                    self.logger.info(
                        "remote_pairing",
                        requestId: requestId,
                        deviceId: deviceId,
                        state: status.logState,
                        nativeCode: status == .success ? nil : "remote_pairing_result_\(resultCode)",
                        payloadBytes: response.data.count,
                        details: "command=\(BleProvisioningCommand.remotePairing.hexCode) responseCommand=\(DoorControlCommand.hex(RemotePairingProtocol.responseCommand)) control=\(DoorControlCommand.hex(control)) result=0x\(String(format: "%02X", resultCode)) reason=\(DoorControlCommand.hex(reasonCode))"
                    )
                    completion(
                        .success(
                            RemotePairingResultDto(
                                requestId: requestId,
                                deviceId: deviceId,
                                status: status,
                                reasonCode: Int64(reasonCode),
                                nativeCode: "command=\(BleProvisioningCommand.remotePairing.hexCode),responseCommand=\(DoorControlCommand.hex(RemotePairingProtocol.responseCommand)),control=\(DoorControlCommand.hex(control)),result=0x\(String(format: "%02X", resultCode)),reason=\(DoorControlCommand.hex(reasonCode))",
                                domainCode: status == .success ? nil : "pairing_failed"
                            )
                        )
                    )
                } failure: { error in
                    completion(.failure(Self.toPigeonError(error)))
                }
            }
        }
    }

    func pairSafetyAccessory(
        requestId: String,
        deviceId: String,
        action: SafetyAccessoryPairingActionDto,
        completion: @escaping (Result<SafetyAccessoryPairingResultDto, Error>) -> Void
    ) {
        let control = action.safetyAccessoryPairingControlCode
        if action == .cancel,
           let pending = pendingProvisioningRequests[deviceId],
           pending.command == .safetyAccessoryPairing {
            pending.timeout.cancel()
            pendingProvisioningRequests.removeValue(forKey: deviceId)
            pending.failure(
                PigeonError(
                    code: "safety_accessory_pairing_cancelled",
                    message: "Safety accessory pairing was cancelled by the user.",
                    details: nil
                )
            )
            logger.info(
                "safety_accessory_pairing",
                requestId: pending.requestId,
                deviceId: deviceId,
                state: "cancelled"
            )
        }

        logger.info(
            "safety_accessory_pairing",
            requestId: requestId,
            deviceId: deviceId,
            state: "started",
            details: "command=\(BleProvisioningCommand.safetyAccessoryPairing.hexCode) control=\(DoorControlCommand.hex(control))"
        )

        ensureProvisioningChannel(requestId: requestId, deviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(Self.toPigeonError(error)))
            case .success:
                self.sendProvisioningRequest(
                    requestId: requestId,
                    deviceId: deviceId,
                    command: .safetyAccessoryPairing,
                    payload: Data(Self.bigEndianBytes(control)),
                    responseTimeout: 30
                ) { response in
                    guard response.data.count >= 5 else {
                        completion(
                            .failure(
                                PigeonError(
                                    code: "invalid_safety_accessory_pairing_response",
                                    message: "Safety accessory pairing response is incomplete.",
                                    details: nil
                                )
                            )
                        )
                        return
                    }

                    let resultCode = response.data[0]
                    let reasonCode = Self.parseUInt32(
                        response.data.dropFirst().prefix(4).asData
                    )
                    let status = SafetyAccessoryPairingStatusDto(resultCode: resultCode)
                    self.logger.info(
                        "safety_accessory_pairing",
                        requestId: requestId,
                        deviceId: deviceId,
                        state: status.logState,
                        nativeCode: status == .success ? nil : "safety_accessory_pairing_result_\(resultCode)",
                        payloadBytes: response.data.count,
                        details: "control=\(DoorControlCommand.hex(control)) result=0x\(String(format: "%02X", resultCode)) reason=\(DoorControlCommand.hex(reasonCode))"
                    )
                    completion(
                        .success(
                            SafetyAccessoryPairingResultDto(
                                requestId: requestId,
                                deviceId: deviceId,
                                status: status,
                                reasonCode: Int64(reasonCode),
                                nativeCode: "command=\(BleProvisioningCommand.safetyAccessoryPairing.hexCode),control=\(DoorControlCommand.hex(control)),result=0x\(String(format: "%02X", resultCode)),reason=\(DoorControlCommand.hex(reasonCode))",
                                domainCode: status == .success ? nil : "pairing_failed"
                            )
                        )
                    )
                } failure: { error in
                    completion(.failure(Self.toPigeonError(error)))
                }
            }
        }
    }

    func querySafetyAccessories(
        requestId: String,
        deviceId: String,
        completion: @escaping (Result<SafetyAccessoryListResultDto, Error>) -> Void
    ) {
        logger.info(
            "safety_accessory_query",
            requestId: requestId,
            deviceId: deviceId,
            state: "started",
            details: "command=\(BleProvisioningCommand.safetyAccessoryQuery.hexCode)"
        )
        ensureProvisioningChannel(requestId: requestId, deviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(Self.toPigeonError(error)))
            case .success:
                self.sendProvisioningRequest(
                    requestId: requestId,
                    deviceId: deviceId,
                    command: .safetyAccessoryQuery,
                    payload: Data()
                ) { response in
                    do {
                        let parsed = try Self.parseSafetyAccessoryList(
                            requestId: requestId,
                            deviceId: deviceId,
                            payload: response.data
                        )
                        let details = parsed.accessories.map { accessory in
                            let serial = UInt32(truncatingIfNeeded: accessory.serialNumber)
                            let type = UInt8((serial >> 24) & 0xFF)
                            return "serial=\(DoorControlCommand.hex(serial)),type=0x\(String(format: "%02X", type)),status=0x\(String(format: "%02X", accessory.statusCode))"
                        }.joined(separator: ";")
                        self.logger.info(
                            "safety_accessory_query",
                            requestId: requestId,
                            deviceId: deviceId,
                            state: "success",
                            payloadBytes: response.data.count,
                            details: "count=\(parsed.totalCount) \(details)"
                        )
                        completion(.success(parsed))
                    } catch {
                        completion(.failure(Self.toPigeonError(error)))
                    }
                } failure: { error in
                    completion(.failure(Self.toPigeonError(error)))
                }
            }
        }
    }

    func deleteSafetyAccessory(
        requestId: String,
        deviceId: String,
        serialNumber: Int64,
        completion: @escaping (Result<SafetyAccessoryDeleteResultDto, Error>) -> Void
    ) {
        let serial = UInt32(truncatingIfNeeded: serialNumber)
        let payload = Self.makeSafetyAccessoryDeletePayload(serialNumber: serial)
        logger.info(
            "safety_accessory_delete",
            requestId: requestId,
            deviceId: deviceId,
            state: "started",
            details: "command=\(BleProvisioningCommand.safetyAccessoryDelete.hexCode) type=0x01 serial=\(DoorControlCommand.hex(serial))"
        )
        ensureProvisioningChannel(requestId: requestId, deviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(Self.toPigeonError(error)))
            case .success:
                self.sendProvisioningRequest(
                    requestId: requestId,
                    deviceId: deviceId,
                    command: .safetyAccessoryDelete,
                    payload: payload
                ) { response in
                    do {
                        let parsed = try Self.parseSafetyAccessoryDeleteResult(
                            requestId: requestId,
                            deviceId: deviceId,
                            payload: response.data
                        )
                        self.logger.info(
                            "safety_accessory_delete",
                            requestId: requestId,
                            deviceId: deviceId,
                            state: parsed.success ? "success" : "failure",
                            nativeCode: parsed.success ? nil : parsed.nativeCode,
                            payloadBytes: response.data.count,
                            details: "serial=\(DoorControlCommand.hex(serial)) reason=\(DoorControlCommand.hex(UInt32(truncatingIfNeeded: parsed.reasonCode)))"
                        )
                        completion(.success(parsed))
                    } catch {
                        completion(.failure(Self.toPigeonError(error)))
                    }
                } failure: { error in
                    completion(.failure(Self.toPigeonError(error)))
                }
            }
        }
    }

    func queryRemotes(
        requestId: String,
        deviceId: String,
        completion: @escaping (Result<RemoteControlListResultDto, Error>) -> Void
    ) {
        logger.info(
            "remote_query",
            requestId: requestId,
            deviceId: deviceId,
            state: "started",
            details: "command=\(BleProvisioningCommand.remoteQuery.hexCode)"
        )

        ensureProvisioningChannel(requestId: requestId, deviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(Self.toPigeonError(error)))
            case .success:
                self.sendProvisioningRequest(
                    requestId: requestId,
                    deviceId: deviceId,
                    command: .remoteQuery,
                    payload: Data()
                ) { response in
                    do {
                        let parsed = try Self.parseRemoteControlList(
                            requestId: requestId,
                            deviceId: deviceId,
                            payload: response.data
                        )
                        self.logger.info(
                            "remote_query",
                            requestId: requestId,
                            deviceId: deviceId,
                            state: "success",
                            payloadBytes: response.data.count,
                            details: "count=\(parsed.totalCount) page=\(parsed.currentPage)/\(parsed.totalPages) hasMore=\(parsed.hasMore)"
                        )
                        completion(.success(parsed))
                    } catch {
                        completion(.failure(Self.toPigeonError(error)))
                    }
                } failure: { error in
                    completion(.failure(Self.toPigeonError(error)))
                }
            }
        }
    }

    func deleteRemote(
        requestId: String,
        deviceId: String,
        serialNumber: Int64?,
        completion: @escaping (Result<RemoteOperationResultDto, Error>) -> Void
    ) {
        let deleteAll = serialNumber == nil
        let serial = UInt32(truncatingIfNeeded: serialNumber ?? 0)
        var payload = Data()
        payload.append(deleteAll ? 0xFF : 0x01)
        payload.append(contentsOf: Self.bigEndianBytes(serial))
        logger.info(
            "remote_delete",
            requestId: requestId,
            deviceId: deviceId,
            state: "started",
            details: "command=\(BleProvisioningCommand.remoteDelete.hexCode) type=\(deleteAll ? "0xFF" : "0x01") serial=\(DoorControlCommand.hex(serial))"
        )

        ensureProvisioningChannel(requestId: requestId, deviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(Self.toPigeonError(error)))
            case .success:
                self.sendProvisioningRequest(
                    requestId: requestId,
                    deviceId: deviceId,
                    command: .remoteDelete,
                    payload: payload
                ) { response in
                    do {
                        let parsed = try Self.parseRemoteOperationResult(
                            requestId: requestId,
                            deviceId: deviceId,
                            payload: response.data,
                            command: .remoteDelete
                        )
                        completion(.success(parsed))
                    } catch {
                        completion(.failure(Self.toPigeonError(error)))
                    }
                } failure: { error in
                    completion(.failure(Self.toPigeonError(error)))
                }
            }
        }
    }

    func renameRemote(
        requestId: String,
        deviceId: String,
        serialNumber: Int64,
        name: String,
        completion: @escaping (Result<RemoteOperationResultDto, Error>) -> Void
    ) {
        let serial = UInt32(truncatingIfNeeded: serialNumber)
        var payload = Self.makeRemoteNamePayload(name)
        payload.append(contentsOf: Self.bigEndianBytes(serial))
        logger.info(
            "remote_rename",
            requestId: requestId,
            deviceId: deviceId,
            state: "started",
            details: "command=\(BleProvisioningCommand.remoteRename.hexCode) serial=\(DoorControlCommand.hex(serial)) nameBytes=8"
        )

        ensureProvisioningChannel(requestId: requestId, deviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(Self.toPigeonError(error)))
            case .success:
                self.sendProvisioningRequest(
                    requestId: requestId,
                    deviceId: deviceId,
                    command: .remoteRename,
                    payload: payload
                ) { response in
                    do {
                        let parsed = try Self.parseRemoteOperationResult(
                            requestId: requestId,
                            deviceId: deviceId,
                            payload: response.data,
                            command: .remoteRename
                        )
                        completion(.success(parsed))
                    } catch {
                        completion(.failure(Self.toPigeonError(error)))
                    }
                } failure: { error in
                    completion(.failure(Self.toPigeonError(error)))
                }
            }
        }
    }
    
    private static func toPigeonError(_ error: Error) -> PigeonError {
        if let pigeonError = error as? PigeonError {
            return pigeonError
        }
        
        guard let bleError = error as? BleManagerError else {
            return PigeonError(
                code: "native_error",
                message: "Native BLE operation failed.",
                details: nil
            )
        }
        
        switch bleError {
        case .bluetoothUnavailable:
            return PigeonError(
                code: "bluetooth_unavailable",
                message: "Bluetooth is not powered on.",
                details: nil
            )
        case .bluetoothUnauthorized:
            return PigeonError(
                code: "bluetooth_unauthorized",
                message: "Bluetooth permission is not granted.",
                details: nil
            )
        case .deviceNotFound(let deviceId):
            return PigeonError(
                code: "device_not_found",
                message: "BLE device was not discovered: \(deviceId)",
                details: nil
            )
        case .peripheralUnavailable(let deviceId):
            return PigeonError(
                code: "peripheral_unavailable",
                message: "BLE device is not connected: \(deviceId)",
                details: nil
            )
        case .serviceNotFound(let serviceUuid):
            return PigeonError(
                code: "service_not_found",
                message: "BLE service was not discovered: \(serviceUuid)",
                details: nil
            )
        case .characteristicNotFound(let characteristicUuid):
            return PigeonError(
                code: "characteristic_not_found",
                message: "BLE characteristic was not discovered: \(characteristicUuid)",
                details: nil
            )
        case .operationInProgress, .operationTimeout, .bluetoothDisconnected:
            return PigeonError(
                code: bleError.nativeCode,
                message: bleError.errorDescription,
                details: nil
            )
        case .operationFailed(let code):
            return PigeonError(code: code, message: nil, details: nil)
        }
    }
}

extension HardwareBridge {
    static func makeEncryptedFrameForTesting(
        sequence: UInt16,
        command: UInt16,
        payload: Data,
        aesKey: Data
    ) -> Data? {
        makeFrame(
            sequence: sequence,
            command: command,
            payload: payload,
            encrypted: true,
            aesKey: aesKey
        )
    }

    static func decryptEcbForTesting(_ encrypted: Data, aesKey: Data) -> Data? {
        decryptAes128(encrypted, key: aesKey, mode: .ecb)
    }

    static func parseDecryptedPayloadForTesting(
        _ plaintext: Data
    ) -> (sequence: UInt16, command: UInt16, data: Data)? {
        guard let frame = parseDecryptedPayload(plaintext, crypto: 0x01) else {
            return nil
        }
        return (frame.sequence, frame.command, frame.data)
    }

    static func parseDeviceAttributesForTesting(
        _ payload: Data
    ) throws -> [(id: Int64, value: Data)] {
        try parseDeviceAttributes(payload).map { ($0.id, $0.value.data) }
    }

    static func makeAttributeWritePayloadForTesting(
        _ attributes: [(id: Int64, value: Data)]
    ) throws -> Data {
        try makeAttributeWritePayload(
            attributes.map {
                DeviceAttributeDto(
                    id: $0.id,
                    value: FlutterStandardTypedData(bytes: $0.value)
                )
            }
        )
    }

    static func makeWifiProvisionPayloadForTesting(
        ssid: String,
        password: String
    ) throws -> Data {
        try makeWifiProvisionPayload(ssid: ssid, password: password)
    }

    static func parseSafetyAccessoryListForTesting(
        _ payload: Data
    ) throws -> [(serialNumber: Int64, statusCode: Int64)] {
        try parseSafetyAccessoryList(
            requestId: "test-query",
            deviceId: "test-device",
            payload: payload
        ).accessories.map { ($0.serialNumber, $0.statusCode) }
    }

    static func makeSafetyAccessoryDeletePayloadForTesting(
        serialNumber: UInt32
    ) -> Data {
        makeSafetyAccessoryDeletePayload(serialNumber: serialNumber)
    }

    static func parseSafetyAccessoryDeleteResultForTesting(
        _ payload: Data
    ) throws -> (success: Bool, reasonCode: Int64) {
        let result = try parseSafetyAccessoryDeleteResult(
            requestId: "test-delete",
            deviceId: "test-device",
            payload: payload
        )
        return (result.success, result.reasonCode)
    }

    static func remotePairingProtocolForTesting(
        start: Bool
    ) -> (
        requestCommand: UInt16,
        responseCommand: UInt16,
        control: UInt16,
        responseTimeout: TimeInterval
    ) {
        (
            BleProvisioningCommand.remotePairing.rawValue,
            RemotePairingProtocol.responseCommand,
            start
                ? RemotePairingProtocol.startControl
                : RemotePairingProtocol.cancelControl,
            RemotePairingProtocol.responseTimeout
        )
    }

    static func matchesProvisioningResponseForTesting(
        expectedCommand: UInt16,
        pendingSequence: UInt16,
        responseCommand: UInt16,
        responseSequence: UInt16
    ) -> Bool {
        matchesProvisioningResponse(
            expectedCommand: expectedCommand,
            pendingSequence: pendingSequence,
            responseCommand: responseCommand,
            responseSequence: responseSequence
        )
    }

    static func remotePairingStatusForTesting(
        resultCode: UInt8
    ) -> RemotePairingStatusDto {
        RemotePairingStatusDto(resultCode: resultCode)
    }

    private static func matchesProvisioningResponse(
        expectedCommand: UInt16,
        pendingSequence: UInt16,
        responseCommand: UInt16,
        responseSequence: UInt16
    ) -> Bool {
        expectedCommand == responseCommand && pendingSequence == responseSequence
    }
}

extension HardwareBridge: BleManagerDelegate {
    func bleManager(_ manager: BleManager, didDiscover device: BleDiscoveredDevice) {
        flutterApi.onBleScanResult(device: device.toDto()) { _ in }
    }
    
    func bleManager(_ manager: BleManager, didChangeConnection event: BleConnectionEvent) {
        if event.state == .disconnected {
            provisioningReadiness[event.deviceId] = nil
            provisioningBuffers[event.deviceId] = nil
            provisioningAesKeys[event.deviceId] = nil
            if let pending = pendingProvisioningRequests.removeValue(forKey: event.deviceId) {
                pending.timeout.cancel()
                pending.failure(
                    PigeonError(
                        code: "bluetooth_disconnected",
                        message: "Bluetooth disconnected while waiting for a command response.",
                        details: nil
                    )
                )
            }
            if let pending = pendingAttributeQueries.removeValue(forKey: event.deviceId) {
                pending.timeout.cancel()
                pending.completion(
                    .failure(
                        PigeonError(
                            code: "bluetooth_disconnected",
                            message: "Bluetooth disconnected while waiting for device attributes.",
                            details: nil
                        )
                    )
                )
            }
        }
        flutterApi.onBleConnectionChanged(event: event.toDto()) { _ in }
    }
    
    func bleManager(_ manager: BleManager, didReceive notification: BleNotification) {
        handleProvisioningNotification(notification)
        flutterApi.onBleNotification(notification: notification.toDto()) { _ in }
    }
    
    func bleManager(_ manager: BleManager, didReceive error: BleNativeError) {
        flutterApi.onNativeError(error: error.toDto()) { _ in }
    }
}

private extension HardwareBridge {
    func ensureProvisioningChannel(
        requestId: String,
        deviceId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        if provisioningReadiness[deviceId] == true {
            logger.info("provisioning_channel", requestId: requestId, deviceId: deviceId, state: "already_ready")
            completion(.success(()))
            return
        }
        
        logger.info("provisioning_channel", requestId: requestId, deviceId: deviceId, state: "discovering")
        bleManager.discoverServices(requestId: requestId, deviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                self.logger.error(
                    "provisioning_channel",
                    requestId: requestId,
                    deviceId: deviceId,
                    nativeCode: "discover_failed",
                    details: "error=\(error.localizedDescription)"
                )
                completion(.failure(error))
            case .success(let services):
                guard Self.containsProvisioningCharacteristics(in: services) else {
                    self.logger.warning(
                        "provisioning_channel",
                        requestId: requestId,
                        deviceId: deviceId,
                        state: "missing_characteristics",
                        nativeCode: "provisioning_characteristic_not_found"
                    )
                    completion(
                        .failure(
                            PigeonError(
                                code: "provisioning_characteristic_not_found",
                                message: "Provisioning service/characteristics are unavailable on this BLE device.",
                                details: nil
                            )
                        )
                    )
                    return
                }
                
                self.bleManager.setCharacteristicNotify(
                    requestId: requestId,
                    deviceId: deviceId,
                    serviceUuid: BleProvisioningCommand.serviceUuid,
                    characteristicUuid: BleProvisioningCommand.notifyCharacteristicUuid,
                    enabled: true
                ) { notifyResult in
                    switch notifyResult {
                    case .failure(let error):
                        self.logger.error(
                            "provisioning_channel",
                            requestId: requestId,
                            deviceId: deviceId,
                            nativeCode: "notify_enable_failed",
                            details: "error=\(error.localizedDescription)"
                        )
                        completion(.failure(error))
                    case .success:
                        self.provisioningReadiness[deviceId] = true
                        self.logger.info("provisioning_channel", requestId: requestId, deviceId: deviceId, state: "ready")
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    func sendProvisioningRequest(
        requestId: String,
        deviceId: String,
        command: BleProvisioningCommand,
        payload: Data,
        responseTimeout: TimeInterval = 15,
        expectedResponseCommand: UInt16? = nil,
        control: UInt16? = nil,
        success: @escaping (BleProtocolFrame) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        if pendingProvisioningRequests[deviceId] != nil || pendingAttributeQueries[deviceId] != nil {
            failure(BleManagerError.operationInProgress("ble_provisioning"))
            return
        }
        
        let sequence = nextProvisioningSequence(for: deviceId)
        let encryptRequest = command.requiresEncryptedRequest
        let aesKey = provisioningAesKeys[deviceId]
        guard let frame = Self.makeFrame(
            sequence: sequence,
            command: command.rawValue,
            payload: payload,
            encrypted: encryptRequest,
            aesKey: aesKey
        ) else {
            logger.error(
                "provisioning_request",
                requestId: requestId,
                deviceId: deviceId,
                nativeCode: "provisioning_encrypt_failed",
                details: "command=\(command.rawValue) sequence=\(sequence)"
            )
            failure(
                PigeonError(
                    code: "provisioning_encrypt_failed",
                    message: "Failed to encrypt BLE provisioning request.",
                    details: nil
                )
            )
            return
        }
        let timeout = DispatchWorkItem { [weak self] in
            guard let self, let pending = self.pendingProvisioningRequests.removeValue(forKey: deviceId) else {
                return
            }
            self.logger.warning(
                "provisioning_response",
                requestId: pending.requestId,
                deviceId: pending.deviceId,
                state: "timeout",
                nativeCode: "provisioning_response_timeout",
                details: "command=\(pending.command.hexCode) commandDecimal=\(pending.command.rawValue)"
            )
            failure(
                PigeonError(
                    code: "provisioning_response_timeout",
                    message: "Timed out waiting for BLE provisioning response for command \(pending.command.rawValue).",
                    details: nil
                )
            )
        }
        
        let responseCommand = expectedResponseCommand ?? command.rawValue
        pendingProvisioningRequests[deviceId] = PendingProvisioningRequest(
            requestId: requestId,
            deviceId: deviceId,
            command: command,
            expectedResponseCommand: responseCommand,
            sequence: sequence,
            timeout: timeout,
            success: success,
            failure: failure
        )
        DispatchQueue.main.asyncAfter(
            deadline: .now() + responseTimeout,
            execute: timeout
        )
        
        logger.info(
            "provisioning_request",
            requestId: requestId,
            deviceId: deviceId,
            state: "sending",
            payloadBytes: frame.count,
            details: "command=\(command.hexCode) commandDecimal=\(command.rawValue) expectedResponseCommand=\(DoorControlCommand.hex(responseCommand)) control=\(control.map { DoorControlCommand.hex($0) } ?? "-") sequence=\(sequence) crypto=\(encryptRequest ? 1 : 0) payloadBytes=\(payload.count) frame=\(logger.payloadHex(frame, sensitive: command == .configureWifi))"
        )
        emitTxDiagnostic(
            requestId: requestId,
            deviceId: deviceId,
            operation: command.displayName,
            command: command.rawValue,
            control: nil,
            sequence: sequence,
            originPayload: Self.makeFrameData(
                sequence: sequence,
                command: command.rawValue,
                payload: payload
            ),
            packet: frame,
            encrypted: encryptRequest,
            sensitive: false,
            expectedResponseCommand: responseCommand
        )
        bleManager.writeCharacteristic(
            requestId: requestId,
            deviceId: deviceId,
            serviceUuid: BleProvisioningCommand.serviceUuid,
            characteristicUuid: BleProvisioningCommand.writeCharacteristicUuid,
            payload: frame,
            writeType: .withResponse
        ) { [weak self] result in
            guard let self else { return }
            if case .failure(let error) = result {
                self.pendingProvisioningRequests.removeValue(forKey: deviceId)?.timeout.cancel()
                self.logger.error(
                    "provisioning_request",
                    requestId: requestId,
                    deviceId: deviceId,
                    nativeCode: "write_failed",
                    details: "command=\(command.hexCode) commandDecimal=\(command.rawValue) error=\(error.localizedDescription)"
                )
                failure(error)
            }
        }
    }

    func sendAttributeQuery(
        requestId: String,
        deviceId: String,
        completion: @escaping (Result<DeviceAttributeSnapshotDto, Error>) -> Void
    ) {
        guard pendingProvisioningRequests[deviceId] == nil,
              pendingAttributeQueries[deviceId] == nil else {
            completion(.failure(Self.toPigeonError(BleManagerError.operationInProgress("device_attributes"))))
            return
        }
        let sequence = nextProvisioningSequence(for: deviceId)
        let payload = Data([0xFF, 0xFF])
        guard let aesKey = provisioningAesKeys[deviceId],
              let frame = Self.makeFrame(
                sequence: sequence,
                command: DeviceAttributeProtocol.queryCommand,
                payload: payload,
                encrypted: true,
                aesKey: aesKey
              ) else {
            completion(
                .failure(
                    PigeonError(
                        code: "attribute_query_encrypt_failed",
                        message: "Failed to encrypt BLE attribute query.",
                        details: nil
                    )
                )
            )
            return
        }
        let timeout = DispatchWorkItem { [weak self] in
            guard let pending = self?.pendingAttributeQueries.removeValue(forKey: deviceId) else {
                return
            }
            pending.completion(
                .failure(
                    PigeonError(
                        code: "command_timeout",
                        message: "Timed out waiting for BLE attribute report.",
                        details: nil
                    )
                )
            )
        }
        pendingAttributeQueries[deviceId] = PendingAttributeQuery(
            requestId: requestId,
            deviceId: deviceId,
            timeout: timeout,
            completion: completion
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeout)
        emitTxDiagnostic(
            requestId: requestId,
            deviceId: deviceId,
            operation: "Query Device Attributes",
            command: DeviceAttributeProtocol.queryCommand,
            control: 0xFFFF,
            sequence: sequence,
            originPayload: Self.makeFrameData(
                sequence: sequence,
                command: DeviceAttributeProtocol.queryCommand,
                payload: payload
            ),
            packet: frame,
            encrypted: true,
            sensitive: false
        )
        bleManager.writeCharacteristic(
            requestId: requestId,
            deviceId: deviceId,
            serviceUuid: BleProvisioningCommand.serviceUuid,
            characteristicUuid: BleProvisioningCommand.writeCharacteristicUuid,
            payload: frame,
            writeType: .withResponse
        ) { [weak self] result in
            guard let self else { return }
            if case .failure(let error) = result,
               let pending = self.pendingAttributeQueries.removeValue(forKey: deviceId) {
                pending.timeout.cancel()
                pending.completion(.failure(Self.toPigeonError(error)))
            }
        }
    }
    
    func handleProvisioningNotification(_ notification: BleNotification) {
        guard notification.serviceUuid.caseInsensitiveCompare(BleProvisioningCommand.serviceUuid) == .orderedSame,
              notification.characteristicUuid.caseInsensitiveCompare(BleProvisioningCommand.notifyCharacteristicUuid) == .orderedSame else {
            return
        }
        
        provisioningBuffers[notification.deviceId, default: Data()].append(notification.payload)
        var buffer = provisioningBuffers[notification.deviceId] ?? Data()
        var parsedFrames: [BleProtocolFrame] = []
        logger.info(
            "provisioning_notification",
            requestId: notification.requestId,
            deviceId: notification.deviceId,
            state: "received",
            payloadBytes: notification.payload.count,
            details: "bufferBytes=\(buffer.count) sequence=\(notification.sequenceNumber)"
        )
        
        while true {
            let parseResult = Self.parseFrame(from: buffer)
            switch parseResult {
            case .notEnoughData:
                provisioningBuffers[notification.deviceId] = buffer
                for frame in parsedFrames {
                    resolveProvisioningFrame(frame, deviceId: notification.deviceId)
                }
                return
            case .invalid(let nextBuffer):
                logger.warning(
                    "provisioning_frame",
                    requestId: notification.requestId,
                    deviceId: notification.deviceId,
                    state: "invalid",
                    details: "remainingBytes=\(nextBuffer.count)"
                )
                buffer = nextBuffer
            case .frame(let frame, let packet, let remainingBuffer):
                logger.info(
                    "provisioning_frame",
                    requestId: notification.requestId,
                    deviceId: notification.deviceId,
                    state: "parsed",
                    payloadBytes: frame.data.count,
                    details: "crypto=\(frame.crypto) type=\(frame.type) sequence=\(frame.sequence) command=\(frame.command) remainingBytes=\(remainingBuffer.count)"
                )
                emitRxDiagnostic(
                    frame: frame,
                    deviceId: notification.deviceId,
                    packet: packet,
                    encryptedPayload: Data()
                )
                parsedFrames.append(frame)
                buffer = remainingBuffer
            case .encrypted(let frame, let packet, let remainingBuffer):
                if let decryptedFrame = decryptEncryptedProvisioningFrame(frame, deviceId: notification.deviceId) {
                    logger.info(
                        "provisioning_frame",
                        requestId: notification.requestId,
                        deviceId: notification.deviceId,
                        state: "decrypted",
                        payloadBytes: decryptedFrame.data.count,
                        details: "crypto=\(frame.crypto) type=\(decryptedFrame.type) sequence=\(decryptedFrame.sequence) command=\(decryptedFrame.command) remainingBytes=\(remainingBuffer.count)"
                    )
                    emitRxDiagnostic(
                        frame: decryptedFrame,
                        deviceId: notification.deviceId,
                        packet: packet,
                        encryptedPayload: frame.encryptedPayload
                    )
                    parsedFrames.append(decryptedFrame)
                } else {
                    let pendingCommand = pendingProvisioningRequests[notification.deviceId]?.command
                    let failureCode = pendingCommand == .authenticate
                        ? "authentication_decrypt_failed"
                        : "encrypted_provisioning_frame_decrypt_failed"
                    logger.warning(
                        "provisioning_frame",
                        requestId: notification.requestId,
                        deviceId: notification.deviceId,
                        state: "decrypt_failed",
                        nativeCode: failureCode,
                        payloadBytes: frame.encryptedPayload.count,
                        details: "crypto=\(frame.crypto) encryptedBytes=\(frame.encryptedPayload.count) rawHex=\(logger.payloadHex(frame.encryptedPayload)) remainingBytes=\(remainingBuffer.count)"
                    )
                    failPendingProvisioningRequest(
                        deviceId: notification.deviceId,
                        code: failureCode,
                        message: pendingCommand == .authenticate
                            ? "BLE authentication response could not be decrypted with the server AES key."
                            : "Received encrypted BLE provisioning frame, but AES128 decrypt did not match the pending command."
                    )
                    if let pending = pendingAttributeQueries.removeValue(forKey: notification.deviceId) {
                        pending.timeout.cancel()
                        pending.completion(
                            .failure(
                                PigeonError(
                                    code: failureCode,
                                    message: "Received an encrypted attribute frame that could not be decrypted.",
                                    details: nil
                                )
                            )
                        )
                    }
                }
                buffer = remainingBuffer
            }
        }
        
        provisioningBuffers[notification.deviceId] = buffer
        for frame in parsedFrames {
            resolveProvisioningFrame(frame, deviceId: notification.deviceId)
        }
    }
    
    func resolveProvisioningFrame(_ frame: BleProtocolFrame, deviceId: String) {
        if frame.command == DeviceAttributeProtocol.reportCommand,
           frame.type == 0x03 || frame.type == 0x04 {
            resolveAttributeReport(frame, deviceId: deviceId)
            return
        }
        guard let pending = pendingProvisioningRequests[deviceId] else {
            logger.info(
                "provisioning_response",
                deviceId: deviceId,
                state: "unsolicited",
                payloadBytes: frame.data.count,
                details: "crypto=\(frame.crypto) type=\(frame.type) command=\(frame.command) sequence=\(frame.sequence)"
            )
            return
        }
        
        guard frame.type == 0x04,
              Self.matchesProvisioningResponse(
                  expectedCommand: pending.expectedResponseCommand,
                  pendingSequence: pending.sequence,
                  responseCommand: frame.command,
                  responseSequence: frame.sequence
              ) else {
            logger.warning(
                "provisioning_response",
                requestId: pending.requestId,
                deviceId: deviceId,
                state: "unmatched",
                details: "type=\(frame.type) command=\(frame.command) sequence=\(frame.sequence) pendingCommand=\(pending.command.rawValue) expectedResponseCommand=\(pending.expectedResponseCommand) pendingSequence=\(pending.sequence)"
            )
            return
        }
        
        pending.timeout.cancel()
        pendingProvisioningRequests.removeValue(forKey: deviceId)
        logger.info(
            "provisioning_response",
            requestId: pending.requestId,
            deviceId: deviceId,
            state: "matched",
            payloadBytes: frame.data.count,
            details: "command=\(frame.command) sequence=\(frame.sequence) pendingCommand=\(pending.command.rawValue) expectedResponseCommand=\(pending.expectedResponseCommand) pendingSequence=\(pending.sequence)"
        )
        pending.success(frame)
    }

    func resolveAttributeReport(_ frame: BleProtocolFrame, deviceId: String) {
        let pending = pendingAttributeQueries.removeValue(forKey: deviceId)
        pending?.timeout.cancel()
        do {
            let attributes = try Self.parseDeviceAttributes(frame.data)
            let snapshot = DeviceAttributeSnapshotDto(
                requestId: pending?.requestId,
                deviceId: deviceId,
                sequence: Int64(frame.sequence),
                timestampMillis: Int64(Date().timeIntervalSince1970 * 1000),
                origin: pending == nil ? .activeReport : .queryResult,
                attributes: attributes
            )
            flutterApi.onDeviceAttributesChanged(snapshot: snapshot) { _ in }
            pending?.completion(.success(snapshot))
        } catch {
            let pigeonError = Self.toPigeonError(error)
            logger.error(
                "device_attribute_report",
                requestId: pending?.requestId,
                deviceId: deviceId,
                nativeCode: pigeonError.code,
                details: "type=\(frame.type) sequence=\(frame.sequence) payloadBytes=\(frame.data.count)"
            )
            flutterApi.onNativeError(
                error: NativeErrorDto(
                    code: pigeonError.code,
                    domainCode: "Unknown",
                    message: pigeonError.message,
                    requestId: pending?.requestId,
                    deviceId: deviceId,
                    retryable: false,
                    timestampMillis: Int64(Date().timeIntervalSince1970 * 1000)
                )
            ) { _ in }
            pending?.completion(.failure(pigeonError))
        }
    }
    
    func failPendingProvisioningRequest(deviceId: String, code: String, message: String) {
        guard let pending = pendingProvisioningRequests.removeValue(forKey: deviceId) else {
            return
        }
        pending.timeout.cancel()
        logger.error(
            "provisioning_response",
            requestId: pending.requestId,
            deviceId: deviceId,
            nativeCode: code,
            details: "command=\(pending.command.rawValue)"
        )
        pending.failure(PigeonError(code: code, message: message, details: nil))
    }
    
    func decryptEncryptedProvisioningFrame(
        _ frame: BleEncryptedProtocolFrame,
        deviceId: String
    ) -> BleProtocolFrame? {
        let pending = pendingProvisioningRequests[deviceId]
        guard let aesKey = provisioningAesKeys[deviceId] else {
            logger.warning(
                "provisioning_decrypt",
                requestId: pending?.requestId,
                deviceId: deviceId,
                state: "missing_aes_key"
            )
            return nil
        }
        
        for mode in BleAesMode.candidateModes {
            guard let plaintext = Self.decryptAes128(
                frame.encryptedPayload,
                key: aesKey,
                mode: mode
            ) else {
                logger.warning(
                    "provisioning_decrypt",
                    requestId: pending?.requestId,
                    deviceId: deviceId,
                    state: "failed",
                    details: "mode=\(mode.name)"
                )
                continue
            }
            logger.info(
                "provisioning_decrypt",
                requestId: pending?.requestId,
                deviceId: deviceId,
                state: "candidate",
                payloadBytes: plaintext.count,
                details: "mode=\(mode.name) plainHex=\(logger.payloadHex(plaintext))"
            )
            guard let decryptedFrame = Self.parseDecryptedPayload(plaintext, crypto: frame.crypto) else {
                continue
            }
            guard let pending else {
                logger.info(
                    "provisioning_decrypt",
                    deviceId: deviceId,
                    state: "success_unsolicited",
                    details: "mode=\(mode.name) type=\(decryptedFrame.type) sequence=\(decryptedFrame.sequence) command=\(decryptedFrame.command)"
                )
                return decryptedFrame
            }
            guard decryptedFrame.type == 0x04,
                  Self.matchesProvisioningResponse(
                      expectedCommand: pending.expectedResponseCommand,
                      pendingSequence: pending.sequence,
                      responseCommand: decryptedFrame.command,
                      responseSequence: decryptedFrame.sequence
                  ) else {
                logger.warning(
                    "provisioning_decrypt",
                    requestId: pending.requestId,
                    deviceId: deviceId,
                    state: "candidate_unmatched",
                    details: "mode=\(mode.name) type=\(decryptedFrame.type) sequence=\(decryptedFrame.sequence) command=\(decryptedFrame.command) pendingSequence=\(pending.sequence) pendingCommand=\(pending.command.rawValue) expectedResponseCommand=\(pending.expectedResponseCommand)"
                )
                return decryptedFrame
            }
            logger.info(
                "provisioning_decrypt",
                requestId: pending.requestId,
                deviceId: deviceId,
                state: "success",
                details: "mode=\(mode.name)"
            )
            return decryptedFrame
        }
        
        return nil
    }
    
    func nextProvisioningSequence(for deviceId: String) -> UInt16 {
        let next = provisioningSequences[deviceId, default: 0] &+ 1
        provisioningSequences[deviceId] = next
        return next
    }

    func emitTxDiagnostic(
        requestId: String,
        deviceId: String,
        operation: String,
        command: UInt16,
        control: UInt16?,
        sequence: UInt16,
        originPayload: Data,
        packet: Data,
        encrypted: Bool,
        sensitive: Bool,
        expectedResponseCommand: UInt16? = nil
    ) {
        guard flutterConsoleLoggingEnabled else { return }
        let transactionId = Self.diagnosticTransactionId(
            deviceId: deviceId,
            command: command,
            sequence: sequence
        )
        let now = Date()
        pendingDiagnostics[transactionId] = PendingBleDiagnostic(
            requestId: requestId,
            deviceId: deviceId,
            operation: operation,
            control: control,
            sequence: sequence,
            expectedResponseCommand: expectedResponseCommand ?? command,
            startedAt: now
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
            guard let current = self?.pendingDiagnostics[transactionId],
                  current.startedAt == now else {
                return
            }
            self?.pendingDiagnostics.removeValue(forKey: transactionId)
        }
        let encryptedPayload = encrypted && packet.count > 8
            ? packet.subdata(in: 5..<(packet.count - 3))
            : Data()
        let safeOrigin = sensitive ? Data() : originPayload
        let safePacket = sensitive && !encrypted ? Data() : packet
        emitDiagnostic(
            BleDiagnosticEventDto(
                direction: .tx,
                timestampMillis: Int64(now.timeIntervalSince1970 * 1000),
                transactionId: transactionId,
                requestId: requestId,
                deviceId: deviceId,
                operation: operation,
                command: Int64(command),
                control: control.map(Int64.init),
                sequence: Int64(sequence),
                encryption: encrypted ? BleAesMode.ecb.name : "None",
                originPayload: FlutterStandardTypedData(bytes: safeOrigin),
                encryptedPayload: FlutterStandardTypedData(bytes: encryptedPayload),
                decryptedPayload: FlutterStandardTypedData(bytes: Data()),
                packet: FlutterStandardTypedData(bytes: safePacket),
                elapsedMillis: nil,
                result: nil
            )
        )
    }

    func emitRxDiagnostic(
        frame: BleProtocolFrame,
        deviceId: String,
        packet: Data,
        encryptedPayload: Data
    ) {
        guard flutterConsoleLoggingEnabled else { return }
        let directId = Self.diagnosticTransactionId(
            deviceId: deviceId,
            command: frame.command,
            sequence: frame.sequence
        )
        let matchedEntry = pendingDiagnostics.removeValue(forKey: directId)
            .map { (directId, $0) }
            ?? pendingDiagnostics.first(where: {
                $0.value.deviceId == deviceId &&
                    $0.value.expectedResponseCommand == frame.command &&
                    $0.value.sequence == frame.sequence
            }).map { key, value in
                pendingDiagnostics.removeValue(forKey: key)
                return (key, value)
            }
        let transactionId = matchedEntry?.0 ?? directId
        let pending = matchedEntry?.1
        let now = Date()
        let decryptedPayload = Self.makeFrameData(
            sequence: frame.sequence,
            command: frame.command,
            payload: frame.data,
            type: frame.type
        )
        emitDiagnostic(
            BleDiagnosticEventDto(
                direction: .rx,
                timestampMillis: Int64(now.timeIntervalSince1970 * 1000),
                transactionId: transactionId,
                requestId: pending?.requestId,
                deviceId: deviceId,
                operation: pending.map { "\($0.operation) Ack" } ?? "Unknown Response",
                command: Int64(frame.command),
                control: pending?.control.map(Int64.init),
                sequence: Int64(frame.sequence),
                encryption: frame.crypto == 0x01 ? BleAesMode.ecb.name : "None",
                originPayload: FlutterStandardTypedData(bytes: Data()),
                encryptedPayload: FlutterStandardTypedData(bytes: encryptedPayload),
                decryptedPayload: FlutterStandardTypedData(bytes: decryptedPayload),
                packet: FlutterStandardTypedData(bytes: packet),
                elapsedMillis: pending.map {
                    Int64(now.timeIntervalSince($0.startedAt) * 1000)
                },
                result: Self.diagnosticResult(frame)
            )
        )
    }

    func emitDiagnostic(_ event: BleDiagnosticEventDto) {
        DispatchQueue.main.async { [flutterApi] in
            flutterApi.onBleDiagnosticEvent(event: event) { _ in }
        }
    }

    static func diagnosticTransactionId(
        deviceId: String,
        command: UInt16,
        sequence: UInt16
    ) -> String {
        "\(deviceId):\(command):\(sequence)"
    }

    static func diagnosticResult(_ frame: BleProtocolFrame) -> String? {
        guard let code = frame.data.first else { return nil }
        let successCode: UInt8 = frame.command == RemotePairingProtocol.responseCommand
            ? RemotePairingProtocol.successResult
            : 0x00
        return code == successCode ? "success" : nil
    }
    
    static func containsProvisioningCharacteristics(in services: BleServices) -> Bool {
        services.services.contains { service in
            guard service.serviceUuid.caseInsensitiveCompare(BleProvisioningCommand.serviceUuid) == .orderedSame else {
                return false
            }
            let characteristicUuids = Set(service.characteristics.map { $0.characteristicUuid.uppercased() })
            return characteristicUuids.contains(BleProvisioningCommand.writeCharacteristicUuid)
            && characteristicUuids.contains(BleProvisioningCommand.notifyCharacteristicUuid)
        }
    }

    static func flowId(from requestId: String) -> String {
        requestId.split(separator: ":", maxSplits: 1).first.map(String.init) ?? "-"
    }

    
    static func makeWifiProvisionPayload(ssid: String, password: String) throws -> Data {
        let options: JSONSerialization.WritingOptions = [.fragmentsAllowed]
        let encodedSsid = try JSONSerialization.data(withJSONObject: ssid, options: options)
        let encodedPassword = try JSONSerialization.data(withJSONObject: password, options: options)
        guard let ssidValue = String(data: encodedSsid, encoding: .utf8),
              let passwordValue = String(data: encodedPassword, encoding: .utf8) else {
            throw PigeonError(
                code: "invalid_wifi_payload",
                message: "Wifi credentials cannot be serialized.",
                details: nil
            )
        }
        return Data("{\"ssid\":\(ssidValue),\"pwd\":\(passwordValue)}".utf8)
    }
    
    static func parseWifiList(from payload: Data) throws -> [String] {
        let data: Data
        if let firstByte = payload.first, firstByte == 0x00 || firstByte == 0x01,
           payload.count > 1, let firstCharacter = payload.dropFirst().first, firstCharacter == UInt8(ascii: "[") {
            data = payload.dropFirst()
        } else {
            data = payload
        }
        
        guard let array = try JSONSerialization.jsonObject(with: data) as? [String] else {
            throw PigeonError(
                code: "invalid_wifi_scan_response",
                message: "Wifi list response is not a UTF-8 JSON array.",
                details: nil
            )
        }
        
        return array
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func parseRemoteControlList(
        requestId: String,
        deviceId: String,
        payload: Data
    ) throws -> RemoteControlListResultDto {
        guard payload.count >= 4 else {
            throw PigeonError(
                code: "invalid_remote_query_response",
                message: "Remote query response is shorter than the required 4-byte header.",
                details: nil
            )
        }

        let totalCount = Int64(payload[payload.startIndex])
        let totalPages = Int64(payload[payload.index(payload.startIndex, offsetBy: 1)])
        let currentPage = Int64(payload[payload.index(payload.startIndex, offsetBy: 2)])
        let packetFlag = payload[payload.index(payload.startIndex, offsetBy: 3)]
        let entryBytes = payload.dropFirst(4).asData
        let entrySize = 12
        var remotes: [RemoteControlDto] = []
        var offset = 0
        while offset + entrySize <= entryBytes.count {
            let nameData = entryBytes.subdata(in: offset..<(offset + 8))
            let serialData = entryBytes.subdata(in: (offset + 8)..<(offset + 12))
            remotes.append(
                RemoteControlDto(
                    name: parseRemoteName(nameData),
                    serialNumber: Int64(parseUInt32(serialData))
                )
            )
            offset += entrySize
        }

        return RemoteControlListResultDto(
            requestId: requestId,
            deviceId: deviceId,
            totalCount: totalCount,
            totalPages: totalPages,
            currentPage: currentPage,
            hasMore: packetFlag == 0x01,
            remotes: remotes
        )
    }

    static func parseSafetyAccessoryList(
        requestId: String,
        deviceId: String,
        payload: Data
    ) throws -> SafetyAccessoryListResultDto {
        guard payload.count >= 2 else {
            throw PigeonError(
                code: "invalid_safety_accessory_query_response",
                message: "Safety accessory query response is missing its 2-byte count.",
                details: nil
            )
        }
        let totalCount = Int(UInt16(payload[0]) << 8 | UInt16(payload[1]))
        let expectedBytes = 2 + totalCount * 5
        guard payload.count == expectedBytes else {
            throw PigeonError(
                code: "invalid_safety_accessory_query_response",
                message: "Safety accessory query response length does not match its count.",
                details: nil
            )
        }
        var accessories: [SafetyAccessoryDto] = []
        accessories.reserveCapacity(totalCount)
        var offset = 2
        while offset < payload.count {
            let serial = parseUInt32(payload.subdata(in: offset..<(offset + 4)))
            let status = payload[offset + 4]
            accessories.append(
                SafetyAccessoryDto(
                    serialNumber: Int64(serial),
                    statusCode: Int64(status)
                )
            )
            offset += 5
        }
        return SafetyAccessoryListResultDto(
            requestId: requestId,
            deviceId: deviceId,
            totalCount: Int64(totalCount),
            accessories: accessories
        )
    }

    static func makeSafetyAccessoryDeletePayload(serialNumber: UInt32) -> Data {
        var payload = Data([0x01])
        payload.append(contentsOf: bigEndianBytes(serialNumber))
        return payload
    }

    static func parseSafetyAccessoryDeleteResult(
        requestId: String,
        deviceId: String,
        payload: Data
    ) throws -> SafetyAccessoryDeleteResultDto {
        guard let resultCode = payload.first else {
            throw PigeonError(
                code: "invalid_safety_accessory_delete_response",
                message: "Safety accessory delete response is empty.",
                details: nil
            )
        }
        let reason = parseUInt32(
            payload.count >= 5 ? payload.dropFirst().prefix(4).asData : Data()
        )
        let success = resultCode == 0x01
        return SafetyAccessoryDeleteResultDto(
            requestId: requestId,
            deviceId: deviceId,
            success: success,
            reasonCode: Int64(reason),
            nativeCode: "command=0x000D,result=0x\(String(format: "%02X", resultCode)),reason=\(DoorControlCommand.hex(reason))",
            domainCode: success ? nil : "safety_accessory_delete_failed"
        )
    }

    static func parseDeviceAttributes(_ payload: Data) throws -> [DeviceAttributeDto] {
        var attributes: [DeviceAttributeDto] = []
        var offset = 0
        while offset < payload.count {
            guard offset + 2 <= payload.count else {
                throw PigeonError(
                    code: "invalid_attribute_payload",
                    message: "Attribute payload ends inside an attribute identifier.",
                    details: nil
                )
            }
            let id = UInt16(payload[offset]) << 8 | UInt16(payload[offset + 1])
            offset += 2
            let value: Data
            if id == DeviceAttributeProtocol.nullTerminatedStringAttribute {
                guard let terminator = payload[offset...].firstIndex(of: 0x00) else {
                    throw PigeonError(
                        code: "invalid_attribute_payload",
                        message: "Null-terminated device name is missing its terminator.",
                        details: nil
                    )
                }
                value = payload.subdata(in: offset..<terminator)
                offset = terminator + 1
            } else {
                guard let width = DeviceAttributeProtocol.valueWidths[id] else {
                    throw PigeonError(
                        code: "unsupported_attribute_schema",
                        message: "No value width is registered for attribute \(DeviceAttributeProtocol.hex(id)).",
                        details: nil
                    )
                }
                guard offset + width <= payload.count else {
                    throw PigeonError(
                        code: "invalid_attribute_payload",
                        message: "Attribute \(DeviceAttributeProtocol.hex(id)) is truncated.",
                        details: nil
                    )
                }
                value = payload.subdata(in: offset..<(offset + width))
                offset += width
            }
            attributes.append(
                DeviceAttributeDto(
                    id: Int64(id),
                    value: FlutterStandardTypedData(bytes: value)
                )
            )
        }
        return attributes
    }

    static func makeAttributeWritePayload(_ attributes: [DeviceAttributeDto]) throws -> Data {
        guard !attributes.isEmpty else {
            throw PigeonError(
                code: "invalid_attribute_write",
                message: "At least one device attribute is required.",
                details: nil
            )
        }
        var payload = Data()
        for attribute in attributes {
            guard let id = UInt16(exactly: attribute.id),
                  DeviceAttributeProtocol.writableAttributes.contains(id),
                  let expectedWidth = DeviceAttributeProtocol.valueWidths[id] else {
                throw PigeonError(
                    code: "unsupported_attribute_write",
                    message: "Attribute 0x\(String(attribute.id, radix: 16).uppercased()) is not writable.",
                    details: nil
                )
            }
            let value = attribute.value.data
            guard value.count == expectedWidth else {
                throw PigeonError(
                    code: "invalid_attribute_write",
                    message: "Attribute \(DeviceAttributeProtocol.hex(id)) requires \(expectedWidth) value bytes.",
                    details: nil
                )
            }
            payload.append(contentsOf: bigEndianBytes(id))
            payload.append(value)
        }
        return payload
    }

    static func parseRemoteOperationResult(
        requestId: String,
        deviceId: String,
        payload: Data,
        command: BleProvisioningCommand
    ) throws -> RemoteOperationResultDto {
        guard payload.count >= 1 else {
            throw PigeonError(
                code: "invalid_remote_operation_response",
                message: "Remote operation response is empty.",
                details: nil
            )
        }
        let resultCode = payload[payload.startIndex]
        let reasonCode = parseUInt32(
            payload.count >= 5
                ? payload.dropFirst().prefix(4).asData
                : Data()
        )
        let status = RemoteOperationStatusDto(resultCode: resultCode)
        return RemoteOperationResultDto(
            requestId: requestId,
            deviceId: deviceId,
            status: status,
            reasonCode: Int64(reasonCode),
            nativeCode: "command=\(command.hexCode),result=0x\(String(format: "%02X", resultCode)),reason=\(DoorControlCommand.hex(reasonCode))",
            domainCode: status == .success ? nil : "remote_operation_failed"
        )
    }

    static func parseRemoteName(_ data: Data) -> String {
        let trimmed = data.prefix { byte in
            byte != 0x00
        }
        guard let name = String(data: Data(trimmed), encoding: .utf8) else {
            return hexString(data)
        }
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func makeRemoteNamePayload(_ name: String) -> Data {
        var payload = Data()
        for character in name.trimmingCharacters(in: .whitespacesAndNewlines) {
            let bytes = String(character).data(using: .utf8) ?? Data()
            if payload.count + bytes.count > 8 {
                break
            }
            payload.append(bytes)
        }
        if payload.count < 8 {
            payload.append(contentsOf: Array(repeating: UInt8(0), count: 8 - payload.count))
        }
        return payload
    }
    
    static func makeFrame(
        sequence: UInt16,
        command: UInt16,
        payload: Data,
        encrypted: Bool = false,
        aesKey: Data? = nil
    ) -> Data? {
        var frame = Data()
        frame.append(contentsOf: [0x55, 0x55])
        let frameData = makeFrameData(sequence: sequence, command: command, payload: payload)
        let crypto: UInt8 = encrypted ? 0x01 : 0x00
        let transmittedData: Data
        if encrypted,
           let aesKey,
           let encryptedData = encryptAes128(
            frameData,
            key: aesKey,
            mode: BleAesMode.ecb
           ) {
            transmittedData = encryptedData
        } else if encrypted {
            return nil
        } else {
            transmittedData = frameData
        }
        let totalLength = UInt16(8 + transmittedData.count)
        frame.append(contentsOf: bigEndianBytes(totalLength))
        frame.append(crypto)
        frame.append(transmittedData)
        let bcc = frame.reduce(UInt8(0)) { partialResult, byte in
            partialResult &+ byte
        }
        frame.append(bcc)
        frame.append(contentsOf: [0xAA, 0xAA])
        return frame
    }
    
    static func makeFrameData(
        sequence: UInt16,
        command: UInt16,
        payload: Data,
        type: UInt8 = 0x03
    ) -> Data {
        var data = Data()
        data.append(type)
        data.append(contentsOf: bigEndianBytes(sequence))
        data.append(contentsOf: bigEndianBytes(command))
        data.append(payload)
        return data
    }
    
    static func parseDecryptedPayload(_ plaintext: Data, crypto: UInt8) -> BleProtocolFrame? {
        guard plaintext.count >= 5 else {
            return nil
        }
        let type = plaintext[plaintext.startIndex]
        let sequenceHighIndex = plaintext.index(plaintext.startIndex, offsetBy: 1)
        let sequenceLowIndex = plaintext.index(after: sequenceHighIndex)
        let commandHighIndex = plaintext.index(plaintext.startIndex, offsetBy: 3)
        let commandLowIndex = plaintext.index(after: commandHighIndex)
        let sequence = UInt16(plaintext[sequenceHighIndex]) << 8 | UInt16(plaintext[sequenceLowIndex])
        let command = UInt16(plaintext[commandHighIndex]) << 8 | UInt16(plaintext[commandLowIndex])
        let payload = plaintext.dropFirst(5).asData
        return BleProtocolFrame(
            crypto: crypto,
            type: type,
            sequence: sequence,
            command: command,
            data: payload
        )
    }
    
    static func decryptAes128(_ encrypted: Data, key: Data, mode: BleAesMode) -> Data? {
        guard key.count == kCCKeySizeAES128 else {
            return nil
        }
        let options = CCOptions(kCCOptionPKCS7Padding | mode.option)
        var output = Data(count: encrypted.count + kCCBlockSizeAES128)
        let encryptedCount = encrypted.count
        let keyCount = key.count
        let outputCount = output.count
        var outputLength = 0
        let status = output.withUnsafeMutableBytes { outputBytes in
            encrypted.withUnsafeBytes { encryptedBytes in
                key.withUnsafeBytes { keyBytes in
                    mode.iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            options,
                            keyBytes.baseAddress,
                            keyCount,
                            mode.usesIv ? ivBytes.baseAddress : nil,
                            encryptedBytes.baseAddress,
                            encryptedCount,
                            outputBytes.baseAddress,
                            outputCount,
                            &outputLength
                        )
                    }
                }
            }
        }
        guard status == kCCSuccess else {
            return nil
        }
        output.removeSubrange(outputLength..<output.count)
        return output
    }
    
    static func encryptAes128(_ plaintext: Data, key: Data, mode: BleAesMode) -> Data? {
        guard key.count == kCCKeySizeAES128 else {
            return nil
        }
        let options = CCOptions(kCCOptionPKCS7Padding | mode.option)
        var output = Data(count: plaintext.count + kCCBlockSizeAES128)
        let plaintextCount = plaintext.count
        let keyCount = key.count
        let outputCount = output.count
        var outputLength = 0
        let status = output.withUnsafeMutableBytes { outputBytes in
            plaintext.withUnsafeBytes { plaintextBytes in
                key.withUnsafeBytes { keyBytes in
                    mode.iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            options,
                            keyBytes.baseAddress,
                            keyCount,
                            mode.usesIv ? ivBytes.baseAddress : nil,
                            plaintextBytes.baseAddress,
                            plaintextCount,
                            outputBytes.baseAddress,
                            outputCount,
                            &outputLength
                        )
                    }
                }
            }
        }
        guard status == kCCSuccess else {
            return nil
        }
        output.removeSubrange(outputLength..<output.count)
        return output
    }
    
    static func hexString(_ data: Data) -> String {
        guard !data.isEmpty else {
            return "none"
        }
        return data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
    
    static func parseFrame(from buffer: Data) -> BleProtocolParseResult {
        guard !buffer.isEmpty else {
            return .notEnoughData
        }
        
        var working = buffer
        while working.count >= 2 {
            let startIndex = working.startIndex
            let nextIndex = working.index(after: startIndex)
            if working[startIndex] == 0x55 && working[nextIndex] == 0x55 {
                break
            }
            working.removeFirst()
        }
        
        guard working.count >= 4 else {
            return .notEnoughData
        }
        
        let lengthStartIndex = working.index(working.startIndex, offsetBy: 2)
        let lengthEndIndex = working.index(after: lengthStartIndex)
        let declaredLength =
        Int(UInt16(working[lengthStartIndex]) << 8 | UInt16(working[lengthEndIndex]))
        guard declaredLength >= 13 else {
            return .invalid(working.dropFirst().asData)
        }
        guard working.count >= declaredLength else {
            return .notEnoughData
        }
        
        let frameBytes = working.prefix(declaredLength).asData
        guard frameBytes.suffix(2) == Data([0xAA, 0xAA]) else {
            return .invalid(working.dropFirst().asData)
        }
        
        let payloadEndIndex = declaredLength - 3
        let expectedBcc = frameBytes[..<payloadEndIndex].reduce(UInt8(0)) { partialResult, byte in
            partialResult &+ byte
        }
        guard expectedBcc == frameBytes[payloadEndIndex] else {
            return .invalid(working.dropFirst().asData)
        }
        
        let cryptoIndex = frameBytes.index(frameBytes.startIndex, offsetBy: 4)
        let crypto = frameBytes[cryptoIndex]
        let remaining = working.dropFirst(declaredLength).asData
        
        if crypto == 0x01 {
            let encryptedStartIndex = frameBytes.index(frameBytes.startIndex, offsetBy: 5)
            let encryptedPayload = frameBytes.subdata(in: encryptedStartIndex..<payloadEndIndex)
            return .encrypted(
                BleEncryptedProtocolFrame(
                    crypto: crypto,
                    encryptedPayload: encryptedPayload
                ),
                frameBytes,
                remaining
            )
        }
        
        guard crypto == 0x00 else {
            return .invalid(working.dropFirst().asData)
        }
        
        let frameTypeIndex = frameBytes.index(frameBytes.startIndex, offsetBy: 5)
        let sequenceHighIndex = frameBytes.index(frameBytes.startIndex, offsetBy: 6)
        let sequenceLowIndex = frameBytes.index(after: sequenceHighIndex)
        let commandHighIndex = frameBytes.index(frameBytes.startIndex, offsetBy: 8)
        let commandLowIndex = frameBytes.index(after: commandHighIndex)
        
        let frameType = frameBytes[frameTypeIndex]
        let sequence =
        UInt16(frameBytes[sequenceHighIndex]) << 8 | UInt16(frameBytes[sequenceLowIndex])
        let command =
        UInt16(frameBytes[commandHighIndex]) << 8 | UInt16(frameBytes[commandLowIndex])
        let payload = frameBytes.subdata(in: 10..<payloadEndIndex)
        
        return .frame(
            BleProtocolFrame(
                crypto: crypto,
                type: frameType,
                sequence: sequence,
                command: command,
                data: payload
            ),
            frameBytes,
            remaining
        )
    }
    
    static func bigEndianBytes<T: FixedWidthInteger>(_ value: T) -> [UInt8] {
        let bigEndian = value.bigEndian
        return withUnsafeBytes(of: bigEndian) { buffer in
            Array(buffer)
        }
    }

    static func parseUInt32(_ data: Data) -> UInt32 {
        guard data.count >= 4 else {
            return 0
        }
        return UInt32(data[data.startIndex]) << 24
        | UInt32(data[data.index(data.startIndex, offsetBy: 1)]) << 16
        | UInt32(data[data.index(data.startIndex, offsetBy: 2)]) << 8
        | UInt32(data[data.index(data.startIndex, offsetBy: 3)])
    }
}

private extension BleScanFilterDto {
    func toNative() -> BleScanFilter {
        BleScanFilter(
            serviceUuids: serviceUuids,
            namePrefix: namePrefix,
            exactName: exactName,
            allowDuplicates: allowDuplicates
        )
    }
}

private extension BleWriteTypeDto {
    func toNative() -> BleWriteType {
        switch self {
        case .withResponse:
            return .withResponse
        case .withoutResponse:
            return .withoutResponse
        }
    }
}

private extension BleDiscoveredDevice {
    func toDto() -> BleDeviceDto {
        BleDeviceDto(
            requestId: requestId,
            scanSessionId: scanSessionId,
            id: id,
            name: name,
            sn: sn,
            rssi: Int64(rssi),
            advertisementServiceUuids: advertisementServiceUuids,
            manufacturerData: FlutterStandardTypedData(bytes: manufacturerData),
            seenAtMillis: seenAtMillis
        )
    }
}

private extension BleConnectionEvent {
    func toDto() -> BleConnectionEventDto {
        BleConnectionEventDto(
            requestId: requestId,
            deviceId: deviceId,
            state: state.toDto(),
            nativeCode: nativeCode
        )
    }
}

private extension BleAuthenticationResult {
    func toDto() -> BleAuthenticationResultDto {
        BleAuthenticationResultDto(
            requestId: requestId,
            deviceId: deviceId,
            authenticated: authenticated,
            bindingState: bindingState,
            nativeCode: nativeCode
        )
    }
}

private extension WifiScanResult {
    func toDto() -> WifiScanResultDto {
        WifiScanResultDto(
            requestId: requestId,
            deviceId: deviceId,
            ssids: ssids
        )
    }
}

private extension WifiProvisionResult {
    func toDto() -> WifiProvisionResultDto {
        WifiProvisionResultDto(
            requestId: requestId,
            deviceId: deviceId,
            ssid: ssid,
            success: success,
            nativeCode: nativeCode
        )
    }
}

private extension BleConnectionState {
    func toDto() -> BleConnectionStateDto {
        switch self {
        case .disconnected:
            return .disconnected
        case .connecting:
            return .connecting
        case .connected:
            return .connected
        }
    }
}

private extension BleServices {
    func toDto() -> BleServicesDto {
        BleServicesDto(
            requestId: requestId,
            deviceId: deviceId,
            services: services.map { $0.toDto() }
        )
    }
}

private extension BleService {
    func toDto() -> BleServiceDto {
        BleServiceDto(
            serviceUuid: serviceUuid,
            characteristics: characteristics.map { $0.toDto() }
        )
    }
}

private extension BleCharacteristic {
    func toDto() -> BleCharacteristicDto {
        BleCharacteristicDto(
            serviceUuid: serviceUuid,
            characteristicUuid: characteristicUuid,
            canRead: canRead,
            canWriteWithResponse: canWriteWithResponse,
            canWriteWithoutResponse: canWriteWithoutResponse,
            canNotify: canNotify
        )
    }
}

private extension BleReadResult {
    func toDto() -> BleReadResultDto {
        BleReadResultDto(
            requestId: requestId,
            deviceId: deviceId,
            serviceUuid: serviceUuid,
            characteristicUuid: characteristicUuid,
            payload: FlutterStandardTypedData(bytes: payload)
        )
    }
}

private extension BleWriteResult {
    func toDto() -> BleWriteResultDto {
        BleWriteResultDto(
            requestId: requestId,
            deviceId: deviceId,
            serviceUuid: serviceUuid,
            characteristicUuid: characteristicUuid,
            accepted: accepted,
            nativeCode: nativeCode
        )
    }
}

private extension BleNotification {
    func toDto() -> BleNotificationDto {
        BleNotificationDto(
            requestId: requestId,
            deviceId: deviceId,
            serviceUuid: serviceUuid,
            characteristicUuid: characteristicUuid,
            payload: FlutterStandardTypedData(bytes: payload),
            timestampMillis: timestampMillis,
            sequenceNumber: sequenceNumber
        )
    }
}

private extension BleNativeError {
    func toDto() -> NativeErrorDto {
        NativeErrorDto(
            code: code,
            domainCode: domainCode,
            message: message,
            requestId: requestId,
            deviceId: deviceId,
            retryable: retryable,
            timestampMillis: timestampMillis
        )
    }
}

private enum BleProvisioningCommand: UInt16 {
    case setAttributes = 0x0001
    case remotePairing = 0x0005
    case remoteQuery = 0x0008
    case remoteDelete = 0x0009
    case remoteRename = 0x000A
    case safetyAccessoryPairing = 0x000B
    case safetyAccessoryQuery = 0x000C
    case safetyAccessoryDelete = 0x000D
    case scanWifi = 0x0E01
    case configureWifi = 0x0E02
    case authenticate = 0x0E03
    
    static let serviceUuid = "02362AF7-CF3A-11E1-EFDC-000215D5C51B"
    static let writeCharacteristicUuid = "02362A10-CF3A-11E1-EFDC-000215D5C51B"
    static let notifyCharacteristicUuid = "02362A11-CF3A-11E1-EFDC-000215D5C51B"
    
    var hexCode: String {
        String(format: "0x%04X", Int(rawValue))
    }

    var displayName: String {
        switch self {
        case .setAttributes: return "Set Device Attributes"
        case .remotePairing: return "Remote Pairing"
        case .remoteQuery: return "Query Remotes"
        case .remoteDelete: return "Delete Remote"
        case .remoteRename: return "Rename Remote"
        case .safetyAccessoryPairing: return "Safety Accessory Pairing"
        case .safetyAccessoryQuery: return "Query Safety Accessories"
        case .safetyAccessoryDelete: return "Delete Safety Accessory"
        case .scanWifi: return "Scan Wi-Fi"
        case .configureWifi: return "Configure Wi-Fi"
        case .authenticate: return "Authenticate Device"
        }
    }
    
    var requiresEncryptedRequest: Bool {
        switch self {
        case .setAttributes, .authenticate, .scanWifi, .remotePairing, .remoteQuery, .remoteDelete, .remoteRename, .safetyAccessoryPairing, .safetyAccessoryQuery, .safetyAccessoryDelete:
            return true
        case .configureWifi:
            return false
        }
    }
    
    func matchesResponseSequence(_ responseSequence: UInt16, pendingSequence: UInt16) -> Bool {
        responseSequence == pendingSequence || (self == .scanWifi && responseSequence == 0)
    }
}

private enum DeviceAttributeProtocol {
    static let queryCommand: UInt16 = 0x0002
    static let reportCommand: UInt16 = 0x0202
    static let nullTerminatedStringAttribute: UInt16 = 0x2700

    static let valueWidths: [UInt16: Int] = [
        0x2702: 2, 0x2703: 2,
        0x2709: 1, 0x2710: 1, 0x2711: 1, 0x2713: 1, 0x2714: 1,
        0x2715: 1, 0x2716: 2, 0x2717: 1, 0x2718: 1, 0x2719: 1,
        0x271A: 2, 0x271B: 1, 0x271C: 1, 0x271D: 1, 0x271F: 1,
        0x2720: 1, 0x2721: 1, 0x2722: 1, 0x2723: 1, 0x2725: 2,
        0x2726: 1, 0x2727: 1, 0x2728: 1, 0x2729: 1, 0x272B: 1,
        0x2735: 1, 0x273B: 1, 0x273C: 1, 0x273D: 1,
    ]

    static let writableAttributes: Set<UInt16> = [
        0x2711, 0x2713, 0x2714, 0x2725, 0x2726, 0x2727, 0x2728,
    ]

    static func hex(_ value: UInt16) -> String {
        String(format: "0x%04X", Int(value))
    }
}

private enum DoorControlCommand {
    static let commandControlDoor: UInt16 = 0x0005
    
    static var hexCode: String {
        hex(commandControlDoor)
    }
    
    static func hex<T: FixedWidthInteger>(_ value: T) -> String {
        String(format: "0x%04X", Int(value))
    }
}

private extension DoorCommandDto {
    var displayName: String {
        switch self {
        case .open: return "Open Door"
        case .close: return "Close Door"
        case .stop: return "Stop Door"
        case .partialOpen: return "Partial Open"
        case .lightOn: return "Light On"
        case .lightOff: return "Light Off"
        case .pb: return "Push Button"
        }
    }

    var doorControlCode: UInt16 {
        switch self {
        case .open:
            return 0x1001
        case .close:
            return 0x1002
        case .stop:
            return 0x1003
        case .partialOpen:
            return 0x1004
        case .lightOn:
            return 0x1005
        case .lightOff:
            return 0x1006
        case .pb:
            return 0x1007
        }
    }
}

private extension RemotePairingActionDto {
    var remotePairingControlCode: UInt16 {
        switch self {
        case .start:
            return RemotePairingProtocol.startControl
        case .cancel:
            return RemotePairingProtocol.cancelControl
        }
    }
}

private enum RemotePairingProtocol {
    static let responseCommand: UInt16 = 0x0104
    static let startControl: UInt16 = 0x1008
    static let cancelControl: UInt16 = 0x1009
    static let successResult: UInt8 = 0x06
    static let failureResult: UInt8 = 0x05
    static let responseTimeout: TimeInterval = 20
}

private extension SafetyAccessoryPairingActionDto {
    var safetyAccessoryPairingControlCode: UInt16 {
        switch self {
        case .start:
            return 0x100A
        case .cancel:
            return 0x100B
        }
    }
}

private extension SafetyAccessoryPairingStatusDto {
    init(resultCode: UInt8) {
        switch resultCode {
        case 0x01:
            self = .success
        case 0x02:
            self = .failure
        case 0x03:
            self = .timeout
        default:
            self = .unknown
        }
    }

    var logState: String {
        switch self {
        case .success: return "success"
        case .failure: return "failure"
        case .timeout: return "timeout"
        case .unknown: return "unknown"
        }
    }
}

private extension RemotePairingStatusDto {
    init(resultCode: UInt8) {
        switch resultCode {
        case RemotePairingProtocol.successResult:
            self = .success
        case RemotePairingProtocol.failureResult:
            self = .failure
        default:
            self = .unknown
        }
    }

    var logState: String {
        switch self {
        case .success:
            return "success"
        case .failure:
            return "failed"
        case .timeout:
            return "timeout"
        case .unknown:
            return "unknown"
        }
    }
}

private extension RemoteOperationStatusDto {
    init(resultCode: UInt8) {
        switch resultCode {
        case 0x01:
            self = .success
        case 0xFF:
            self = .failure
        default:
            self = .unknown
        }
    }
}

private struct BleAesMode {
    let name: String
    let option: Int
    let iv: Data
    
    var usesIv: Bool {
        !iv.isEmpty
    }
    
    static let ecb = BleAesMode(name: "AES-128-ECB-PKCS7", option: kCCOptionECBMode, iv: Data())
    
    static let candidateModes = [
        ecb,
        BleAesMode(name: "AES-128-CBC-PKCS7-zero-IV", option: 0, iv: Data(repeating: 0, count: kCCBlockSizeAES128)),
    ]
}

private struct PendingProvisioningRequest {
    let requestId: String
    let deviceId: String
    let command: BleProvisioningCommand
    let expectedResponseCommand: UInt16
    let sequence: UInt16
    let timeout: DispatchWorkItem
    let success: (BleProtocolFrame) -> Void
    let failure: (Error) -> Void
}

private struct PendingAttributeQuery {
    let requestId: String
    let deviceId: String
    let timeout: DispatchWorkItem
    let completion: (Result<DeviceAttributeSnapshotDto, Error>) -> Void
}

private struct PendingBleDiagnostic {
    let requestId: String
    let deviceId: String
    let operation: String
    let control: UInt16?
    let sequence: UInt16
    let expectedResponseCommand: UInt16
    let startedAt: Date
}

private struct BleProtocolFrame {
    let crypto: UInt8
    let type: UInt8
    let sequence: UInt16
    let command: UInt16
    let data: Data
}

private struct BleEncryptedProtocolFrame {
    let crypto: UInt8
    let encryptedPayload: Data
}

private enum BleProtocolParseResult {
    case notEnoughData
    case invalid(Data)
    case frame(BleProtocolFrame, Data, Data)
    case encrypted(BleEncryptedProtocolFrame, Data, Data)
}

private extension Data.SubSequence {
    var asData: Data { Data(self) }
}

private extension Data {
    init?(hexString: String) {
        let normalized = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count.isMultiple(of: 2) else {
            return nil
        }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(normalized.count / 2)
        var index = normalized.startIndex
        while index < normalized.endIndex {
            let nextIndex = normalized.index(index, offsetBy: 2)
            guard let byte = UInt8(normalized[index..<nextIndex], radix: 16) else {
                return nil
            }
            bytes.append(byte)
            index = nextIndex
        }
        self = Data(bytes)
    }
}
