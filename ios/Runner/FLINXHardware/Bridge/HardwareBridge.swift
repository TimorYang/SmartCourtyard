import CoreBluetooth
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
    try bleManager.startScan(requestId: requestId, filter: filter)
  }

  func stopBleScan(requestId: String) throws {
    _ = requestId
    bleManager.stopScan()
  }

  func connectBleDevice(
    requestId: String,
    deviceId: String,
    completion: @escaping (Result<BleConnectionEventDto, Error>) -> Void
  ) {
    bleManager.connect(requestId: requestId, deviceId: deviceId) { result in
      completion(result.mapError(Self.toPigeonError))
    }
  }

  func disconnectBleDevice(
    requestId: String,
    deviceId: String,
    completion: @escaping (Result<BleConnectionEventDto, Error>) -> Void
  ) {
    bleManager.disconnect(requestId: requestId, deviceId: deviceId) { result in
      completion(result.mapError(Self.toPigeonError))
    }
  }

  func discoverServices(
    requestId: String,
    deviceId: String,
    completion: @escaping (Result<BleServicesDto, Error>) -> Void
  ) {
    bleManager.discoverServices(requestId: requestId, deviceId: deviceId) { result in
      completion(result.mapError(Self.toPigeonError))
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
      completion(result.mapError(Self.toPigeonError))
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
      payload: payload,
      writeType: writeType
    ) { result in
      completion(result.mapError(Self.toPigeonError))
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
      completion(result.mapError(Self.toPigeonError))
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

    switch error {
    case BleManagerError.bluetoothUnavailable:
      return PigeonError(
        code: "bluetooth_unavailable",
        message: "Bluetooth is not powered on.",
        details: nil
      )
    case BleManagerError.bluetoothUnauthorized:
      return PigeonError(
        code: "bluetooth_unauthorized",
        message: "Bluetooth permission is not granted.",
        details: nil
      )
    case BleManagerError.deviceNotFound(let deviceId):
      return PigeonError(
        code: "device_not_found",
        message: "BLE device was not discovered: \(deviceId)",
        details: nil
      )
    case BleManagerError.peripheralUnavailable(let deviceId):
      return PigeonError(
        code: "peripheral_unavailable",
        message: "BLE device is not connected: \(deviceId)",
        details: nil
      )
    case BleManagerError.serviceNotFound(let serviceUuid):
      return PigeonError(
        code: "service_not_found",
        message: "BLE service was not discovered: \(serviceUuid)",
        details: nil
      )
    case BleManagerError.characteristicNotFound(let characteristicUuid):
      return PigeonError(
        code: "characteristic_not_found",
        message: "BLE characteristic was not discovered: \(characteristicUuid)",
        details: nil
      )
    case BleManagerError.operationFailed(let code):
      return PigeonError(code: code, message: nil, details: nil)
    default:
      return PigeonError(
        code: "native_error",
        message: error.localizedDescription,
        details: nil
      )
    }
  }
}

extension HardwareBridge: BleManagerDelegate {
  func bleManager(_ manager: BleManager, didDiscover device: BleDeviceDto) {
    flutterApi.onBleScanResult(device: device) { _ in }
  }

  func bleManager(_ manager: BleManager, didChangeConnection event: BleConnectionEventDto) {
    flutterApi.onBleConnectionChanged(event: event) { _ in }
  }

  func bleManager(_ manager: BleManager, didReceive notification: BleNotificationDto) {
    flutterApi.onBleNotification(notification: notification) { _ in }
  }

  func bleManager(_ manager: BleManager, didReceive error: NativeErrorDto) {
    flutterApi.onNativeError(error: error) { _ in }
  }
}
