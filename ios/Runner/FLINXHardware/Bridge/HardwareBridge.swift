import Flutter
import Foundation

final class HardwareBridge: HardwareHostApi {
    private let bleManager: BleManager
    private let logger: BleLogger
    private let flutterApi: HardwareFlutterApi
    private var provisioningReadiness: [String: Bool] = [:]
    private var provisioningBuffers: [String: Data] = [:]
    private var pendingProvisioningRequests: [String: PendingProvisioningRequest] = [:]
    private var provisioningSequences: [String: UInt16] = [:]
    
    init(binaryMessenger: FlutterBinaryMessenger) {
        self.logger = BleLogger()
        self.bleManager = BleManager(logger: logger)
        self.flutterApi = HardwareFlutterApi(binaryMessenger: binaryMessenger)
        self.bleManager.delegate = self
    }
    
    func getPermissionSnapshot() throws -> PermissionSnapshotDto {
        PermissionSnapshotDto(
            bluetoothGranted: bleManager.bluetoothGranted(),
            cameraGranted: false,
            localNetworkGranted: false,
            notificationGranted: false
        )
    }
    
    func requestPermissions(permissions: [PermissionKindDto]) throws -> PermissionSnapshotDto {
        if permissions.contains(.bluetooth) {
            bleManager.prepareForPermissionRequest()
        }
        return try getPermissionSnapshot()
    }
    
    func startBleScan(requestId: String, filter: BleScanFilterDto) throws {
        try bleManager.startScan(requestId: requestId, filter: filter.toNative())
    }
    
    func stopBleScan(requestId: String) throws {
        bleManager.stopScan(requestId: requestId)
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
        completion: @escaping (Result<BleAuthenticationResultDto, Error>) -> Void
    ) {
        logger.info("ble_authenticate", requestId: requestId, deviceId: deviceId, state: "started")
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
        command: DoorCommandDto
    ) throws -> CommandResultDto {
        _ = command
        return CommandResultDto(
            requestId: requestId,
            deviceId: deviceId,
            accepted: false,
            nativeCode: "not_implemented",
            domainCode: "hardware_command_not_implemented"
        )
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

extension HardwareBridge: BleManagerDelegate {
    func bleManager(_ manager: BleManager, didDiscover device: BleDiscoveredDevice) {
        flutterApi.onBleScanResult(device: device.toDto()) { _ in }
    }
    
    func bleManager(_ manager: BleManager, didChangeConnection event: BleConnectionEvent) {
        if event.state == .disconnected {
            provisioningReadiness[event.deviceId] = nil
            provisioningBuffers[event.deviceId] = nil
            pendingProvisioningRequests.removeValue(forKey: event.deviceId)?.timeout.cancel()
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
        success: @escaping (BleProtocolFrame) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        if pendingProvisioningRequests[deviceId] != nil {
            failure(BleManagerError.operationInProgress("ble_provisioning"))
            return
        }
        
        let sequence = nextProvisioningSequence(for: deviceId)
        guard let frame = Self.makeFrame(
            sequence: sequence,
            command: command.rawValue,
            payload: payload,
            encrypted: command == .authenticate
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
                details: "command=\(pending.command.rawValue)"
            )
            failure(
                PigeonError(
                    code: "provisioning_response_timeout",
                    message: "Timed out waiting for BLE provisioning response for command \(pending.command.rawValue).",
                    details: nil
                )
            )
        }
        
        pendingProvisioningRequests[deviceId] = PendingProvisioningRequest(
            requestId: requestId,
            deviceId: deviceId,
            command: command,
            sequence: sequence,
            timeout: timeout,
            success: success,
            failure: failure
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: timeout)
        
        logger.info(
            "provisioning_request",
            requestId: requestId,
            deviceId: deviceId,
            state: "sending",
            payloadBytes: frame.count,
            details: "command=\(command.rawValue) sequence=\(sequence) crypto=\(command == .authenticate ? 1 : 0) payloadBytes=\(payload.count) frame=\(Self.hexString(frame))"
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
                    details: "command=\(command.rawValue) error=\(error.localizedDescription)"
                )
                failure(error)
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
            case .frame(let frame, let remainingBuffer):
                logger.info(
                    "provisioning_frame",
                    requestId: notification.requestId,
                    deviceId: notification.deviceId,
                    state: "parsed",
                    payloadBytes: frame.data.count,
                    details: "crypto=\(frame.crypto) type=\(frame.type) sequence=\(frame.sequence) command=\(frame.command) remainingBytes=\(remainingBuffer.count)"
                )
                parsedFrames.append(frame)
                buffer = remainingBuffer
            case .encrypted(let frame, let remainingBuffer):
                if let decryptedFrame = decryptEncryptedProvisioningFrame(frame, deviceId: notification.deviceId) {
                    logger.info(
                        "provisioning_frame",
                        requestId: notification.requestId,
                        deviceId: notification.deviceId,
                        state: "decrypted",
                        payloadBytes: decryptedFrame.data.count,
                        details: "crypto=\(frame.crypto) type=\(decryptedFrame.type) sequence=\(decryptedFrame.sequence) command=\(decryptedFrame.command) remainingBytes=\(remainingBuffer.count)"
                    )
                    parsedFrames.append(decryptedFrame)
                } else {
                    logger.warning(
                        "provisioning_frame",
                        requestId: notification.requestId,
                        deviceId: notification.deviceId,
                        state: "decrypt_failed",
                        payloadBytes: frame.encryptedPayload.count,
                        details: "crypto=\(frame.crypto) encryptedBytes=\(frame.encryptedPayload.count) remainingBytes=\(remainingBuffer.count)"
                    )
                    failPendingProvisioningRequest(
                        deviceId: notification.deviceId,
                        code: "encrypted_provisioning_frame_decrypt_failed",
                        message: "Received encrypted BLE provisioning frame, but AES128 decrypt did not match the pending command."
                    )
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
              pending.command.rawValue == frame.command,
              pending.sequence == frame.sequence else {
            logger.warning(
                "provisioning_response",
                deviceId: deviceId,
                state: "unmatched",
                details: "type=\(frame.type) command=\(frame.command) sequence=\(frame.sequence) pendingCommand=\(pending.command.rawValue) pendingSequence=\(pending.sequence)"
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
            details: "command=\(frame.command) sequence=\(frame.sequence) pendingCommand=\(pending.command.rawValue) pendingSequence=\(pending.sequence)"
        )
        pending.success(frame)
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
        
        for mode in BleAesMode.candidateModes {
            guard let plaintext = Self.decryptAes128(
                frame.encryptedPayload,
                key: BleProvisioningCommand.candidateAesKey,
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
                details: "mode=\(mode.name) plaintext=\(Self.hexString(plaintext))"
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
                  decryptedFrame.command == pending.command.rawValue,
                  decryptedFrame.sequence == pending.sequence else {
                logger.warning(
                    "provisioning_decrypt",
                    requestId: pending.requestId,
                    deviceId: deviceId,
                    state: "candidate_unmatched",
                    details: "mode=\(mode.name) type=\(decryptedFrame.type) sequence=\(decryptedFrame.sequence) command=\(decryptedFrame.command) pendingSequence=\(pending.sequence) pendingCommand=\(pending.command.rawValue)"
                )
                continue
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
    
    static func makeWifiProvisionPayload(ssid: String, password: String) throws -> Data {
        let jsonObject: [String: String] = ["ssid": ssid, "pwd": password]
        guard JSONSerialization.isValidJSONObject(jsonObject) else {
            throw PigeonError(
                code: "invalid_wifi_payload",
                message: "Wifi credentials cannot be serialized.",
                details: nil
            )
        }
        return try JSONSerialization.data(withJSONObject: jsonObject, options: [])
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
    
    static func makeFrame(
        sequence: UInt16,
        command: UInt16,
        payload: Data,
        encrypted: Bool = false
    ) -> Data? {
        var frame = Data()
        frame.append(contentsOf: [0x55, 0x55])
        let frameData = makeFrameData(sequence: sequence, command: command, payload: payload)
        let crypto: UInt8 = encrypted ? 0x01 : 0x00
        let transmittedData: Data
        if encrypted,
           let encryptedData = encryptAes128(
            frameData,
            key: BleProvisioningCommand.candidateAesKey,
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
    
    static func makeFrameData(sequence: UInt16, command: UInt16, payload: Data) -> Data {
        var data = Data()
        data.append(0x03)
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
            remaining
        )
    }
    
    static func bigEndianBytes<T: FixedWidthInteger>(_ value: T) -> [UInt8] {
        let bigEndian = value.bigEndian
        return withUnsafeBytes(of: bigEndian) { buffer in
            Array(buffer)
        }
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
    case scanWifi = 0x0E01
    case configureWifi = 0x0E02
    case authenticate = 0x0E03
    
    static let serviceUuid = "02362AF7-CF3A-11E1-EFDC-000215D5C51B"
    static let writeCharacteristicUuid = "02362A10-CF3A-11E1-EFDC-000215D5C51B"
    static let notifyCharacteristicUuid = "02362A11-CF3A-11E1-EFDC-000215D5C51B"
    static let candidateAesKey = Data(hexString: "1BEE89494F466512FF584DDF85B39AA6") ?? Data()
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
    let sequence: UInt16
    let timeout: DispatchWorkItem
    let success: (BleProtocolFrame) -> Void
    let failure: (Error) -> Void
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
    case frame(BleProtocolFrame, Data)
    case encrypted(BleEncryptedProtocolFrame, Data)
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
