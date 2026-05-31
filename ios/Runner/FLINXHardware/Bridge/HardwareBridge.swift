import Flutter
import Foundation

final class HardwareBridge: HardwareHostApi {
  private let bleManager: BleManager
  private let flutterApi: HardwareFlutterApi

  init(binaryMessenger: FlutterBinaryMessenger) {
    self.bleManager = BleManager()
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
    flutterApi.onBleConnectionChanged(event: event.toDto()) { _ in }
  }

  func bleManager(_ manager: BleManager, didReceive notification: BleNotification) {
    flutterApi.onBleNotification(notification: notification.toDto()) { _ in }
  }

  func bleManager(_ manager: BleManager, didReceive error: BleNativeError) {
    flutterApi.onNativeError(error: error.toDto()) { _ in }
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
