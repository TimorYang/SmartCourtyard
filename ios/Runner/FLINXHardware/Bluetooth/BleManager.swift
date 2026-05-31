import CoreBluetooth
import Flutter
import Foundation

protocol BleManagerDelegate: AnyObject {
  func bleManager(_ manager: BleManager, didDiscover device: BleDeviceDto)
  func bleManager(_ manager: BleManager, didChangeConnection event: BleConnectionEventDto)
  func bleManager(_ manager: BleManager, didReceive notification: BleNotificationDto)
  func bleManager(_ manager: BleManager, didReceive error: NativeErrorDto)
}

enum BleManagerError: Error {
  case bluetoothUnavailable
  case bluetoothUnauthorized
  case deviceNotFound(String)
  case peripheralUnavailable(String)
  case serviceNotFound(String)
  case characteristicNotFound(String)
  case operationFailed(String)
}

final class BleManager: NSObject {
  weak var delegate: BleManagerDelegate?

  private lazy var centralManager = CBCentralManager(delegate: self, queue: .main)
  private var peripheralsById: [String: CBPeripheral] = [:]
  private var scanFilter: BleScanFilterDto?

  private var pendingConnects:
    [String: (requestId: String, completion: (Result<BleConnectionEventDto, Error>) -> Void)] = [:]
  private var pendingDisconnects:
    [String: (requestId: String, completion: (Result<BleConnectionEventDto, Error>) -> Void)] = [:]
  private var pendingDiscoveries:
    [String: (requestId: String, remainingServices: Int, completion: (Result<BleServicesDto, Error>) -> Void)] = [:]
  private var pendingReads:
    [String: (requestId: String, completion: (Result<BleReadResultDto, Error>) -> Void)] = [:]
  private var pendingWrites:
    [String: (requestId: String, completion: (Result<BleWriteResultDto, Error>) -> Void)] = [:]
  private var pendingNotifyChanges:
    [String: (requestId: String, enabled: Bool, completion: (Result<BleWriteResultDto, Error>) -> Void)] = [:]

  func bluetoothGranted() -> Bool {
    if #available(iOS 13.1, *) {
      return CBCentralManager.authorization == .allowedAlways
    }
    return true
  }

  func prepareForPermissionRequest() {
    _ = centralManager.state
  }

  func startScan(requestId: String, filter: BleScanFilterDto) throws {
    try ensureBluetoothReady(requestId: requestId)
    scanFilter = filter
    let serviceUuids = filter.serviceUuids.map(CBUUID.init(string:))
    centralManager.scanForPeripherals(
      withServices: serviceUuids.isEmpty ? nil : serviceUuids,
      options: [CBCentralManagerScanOptionAllowDuplicatesKey: filter.allowDuplicates]
    )
  }

  func stopScan() {
    centralManager.stopScan()
  }

  func connect(
    requestId: String,
    deviceId: String,
    completion: @escaping (Result<BleConnectionEventDto, Error>) -> Void
  ) {
    guard let peripheral = peripheralsById[deviceId] else {
      completion(.failure(BleManagerError.deviceNotFound(deviceId)))
      return
    }

    peripheral.delegate = self
    pendingConnects[deviceId] = (requestId, completion)
    emitConnection(requestId: requestId, deviceId: deviceId, state: .connecting)
    centralManager.connect(peripheral)
  }

  func disconnect(
    requestId: String,
    deviceId: String,
    completion: @escaping (Result<BleConnectionEventDto, Error>) -> Void
  ) {
    guard let peripheral = peripheralsById[deviceId] else {
      completion(.failure(BleManagerError.deviceNotFound(deviceId)))
      return
    }

    if peripheral.state == .disconnected {
      let event = BleConnectionEventDto(
        requestId: requestId,
        deviceId: deviceId,
        state: .disconnected,
        nativeCode: nil
      )
      delegate?.bleManager(self, didChangeConnection: event)
      completion(.success(event))
      return
    }

    pendingDisconnects[deviceId] = (requestId, completion)
    centralManager.cancelPeripheralConnection(peripheral)
  }

  func discoverServices(
    requestId: String,
    deviceId: String,
    completion: @escaping (Result<BleServicesDto, Error>) -> Void
  ) {
    guard let peripheral = connectedPeripheral(deviceId: deviceId, completion: completion) else {
      return
    }

    peripheral.delegate = self
    pendingDiscoveries[deviceId] = (requestId, 0, completion)
    peripheral.discoverServices(nil)
  }

  func readCharacteristic(
    requestId: String,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    completion: @escaping (Result<BleReadResultDto, Error>) -> Void
  ) {
    guard let peripheral = connectedPeripheral(deviceId: deviceId, completion: completion) else {
      return
    }
    guard let characteristic = findCharacteristic(
      peripheral: peripheral,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid
    ) else {
      completion(.failure(BleManagerError.characteristicNotFound(characteristicUuid)))
      return
    }

    pendingReads[characteristicKey(deviceId, characteristic)] = (requestId, completion)
    peripheral.readValue(for: characteristic)
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
    guard let peripheral = connectedPeripheral(deviceId: deviceId, completion: completion) else {
      return
    }
    guard let characteristic = findCharacteristic(
      peripheral: peripheral,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid
    ) else {
      completion(.failure(BleManagerError.characteristicNotFound(characteristicUuid)))
      return
    }

    let result = BleWriteResultDto(
      requestId: requestId,
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      accepted: true,
      nativeCode: nil
    )

    let cbWriteType: CBCharacteristicWriteType =
      writeType == .withoutResponse ? .withoutResponse : .withResponse
    if cbWriteType == .withResponse {
      pendingWrites[characteristicKey(deviceId, characteristic)] = (requestId, completion)
    }

    peripheral.writeValue(payload.data, for: characteristic, type: cbWriteType)

    if cbWriteType == .withoutResponse {
      completion(.success(result))
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
    guard let peripheral = connectedPeripheral(deviceId: deviceId, completion: completion) else {
      return
    }
    guard let characteristic = findCharacteristic(
      peripheral: peripheral,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid
    ) else {
      completion(.failure(BleManagerError.characteristicNotFound(characteristicUuid)))
      return
    }

    pendingNotifyChanges[characteristicKey(deviceId, characteristic)] = (
      requestId,
      enabled,
      completion
    )
    peripheral.setNotifyValue(enabled, for: characteristic)
  }

  private func ensureBluetoothReady(requestId: String) throws {
    if #available(iOS 13.1, *), CBCentralManager.authorization == .denied {
      throw BleManagerError.bluetoothUnauthorized
    }
    guard centralManager.state == .poweredOn else {
      emitNativeError(
        code: "bluetooth_unavailable",
        message: "Bluetooth is not powered on.",
        requestId: requestId,
        deviceId: nil
      )
      throw BleManagerError.bluetoothUnavailable
    }
  }

  private func connectedPeripheral<T>(
    deviceId: String,
    completion: (Result<T, Error>) -> Void
  ) -> CBPeripheral? {
    guard let peripheral = peripheralsById[deviceId] else {
      completion(.failure(BleManagerError.deviceNotFound(deviceId)))
      return nil
    }
    guard peripheral.state == .connected else {
      completion(.failure(BleManagerError.peripheralUnavailable(deviceId)))
      return nil
    }
    return peripheral
  }

  private func findCharacteristic(
    peripheral: CBPeripheral,
    serviceUuid: String,
    characteristicUuid: String
  ) -> CBCharacteristic? {
    peripheral.services?
      .first { $0.uuid.uuidString.caseInsensitiveCompare(serviceUuid) == .orderedSame }?
      .characteristics?
      .first { $0.uuid.uuidString.caseInsensitiveCompare(characteristicUuid) == .orderedSame }
  }

  private func completeDiscovery(for peripheral: CBPeripheral) {
    let deviceId = peripheral.identifier.uuidString
    guard let pending = pendingDiscoveries.removeValue(forKey: deviceId) else {
      return
    }

    let services = peripheral.services?.map { service in
      BleServiceDto(
        serviceUuid: service.uuid.uuidString,
        characteristics: (service.characteristics ?? []).map { characteristic in
          BleCharacteristicDto(
            serviceUuid: service.uuid.uuidString,
            characteristicUuid: characteristic.uuid.uuidString,
            canRead: characteristic.properties.contains(.read),
            canWriteWithResponse: characteristic.properties.contains(.write),
            canWriteWithoutResponse: characteristic.properties.contains(.writeWithoutResponse),
            canNotify: characteristic.properties.contains(.notify)
              || characteristic.properties.contains(.indicate)
          )
        }
      )
    } ?? []

    pending.completion(
      .success(
        BleServicesDto(
          requestId: pending.requestId,
          deviceId: deviceId,
          services: services
        )
      )
    )
  }

  private func characteristicKey(_ deviceId: String, _ characteristic: CBCharacteristic) -> String {
    let serviceUuid = characteristic.service?.uuid.uuidString ?? ""
    return "\(deviceId)|\(serviceUuid)|\(characteristic.uuid.uuidString)"
  }

  private func emitConnection(
    requestId: String,
    deviceId: String,
    state: BleConnectionStateDto,
    nativeCode: String? = nil
  ) {
    let event = BleConnectionEventDto(
      requestId: requestId,
      deviceId: deviceId,
      state: state,
      nativeCode: nativeCode
    )
    delegate?.bleManager(self, didChangeConnection: event)
  }

  private func emitNativeError(
    code: String,
    message: String?,
    requestId: String?,
    deviceId: String?
  ) {
    delegate?.bleManager(
      self,
      didReceive: NativeErrorDto(
        code: code,
        message: message,
        requestId: requestId,
        deviceId: deviceId
      )
    )
  }
}

extension BleManager: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state != .poweredOn {
      emitNativeError(
        code: "bluetooth_unavailable",
        message: "Bluetooth state changed to \(central.state.rawValue).",
        requestId: nil,
        deviceId: nil
      )
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
    if let exactName = scanFilter?.exactName, name != exactName {
      return
    }
    if let namePrefix = scanFilter?.namePrefix, name?.hasPrefix(namePrefix) != true {
      return
    }

    let deviceId = peripheral.identifier.uuidString
    peripheralsById[deviceId] = peripheral
    peripheral.delegate = self

    let serviceUuids = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?
      .map(\.uuidString) ?? []
    let manufacturerData =
      advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data ?? Data()

    delegate?.bleManager(
      self,
      didDiscover: BleDeviceDto(
        id: deviceId,
        name: name,
        rssi: Int64(RSSI.intValue),
        advertisementServiceUuids: serviceUuids,
        manufacturerData: FlutterStandardTypedData(bytes: manufacturerData)
      )
    )
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    let deviceId = peripheral.identifier.uuidString
    let requestId = pendingConnects[deviceId]?.requestId ?? ""
    let event = BleConnectionEventDto(
      requestId: requestId,
      deviceId: deviceId,
      state: .connected,
      nativeCode: nil
    )
    delegate?.bleManager(self, didChangeConnection: event)
    pendingConnects.removeValue(forKey: deviceId)?.completion(.success(event))
  }

  func centralManager(
    _ central: CBCentralManager,
    didFailToConnect peripheral: CBPeripheral,
    error: Error?
  ) {
    let deviceId = peripheral.identifier.uuidString
    emitNativeError(
      code: "connect_failed",
      message: error?.localizedDescription,
      requestId: pendingConnects[deviceId]?.requestId,
      deviceId: deviceId
    )
    pendingConnects.removeValue(forKey: deviceId)?.completion(
      .failure(error ?? BleManagerError.operationFailed("connect_failed"))
    )
  }

  func centralManager(
    _ central: CBCentralManager,
    didDisconnectPeripheral peripheral: CBPeripheral,
    error: Error?
  ) {
    let deviceId = peripheral.identifier.uuidString
    let requestId = pendingDisconnects[deviceId]?.requestId ?? pendingConnects[deviceId]?.requestId ?? ""
    let event = BleConnectionEventDto(
      requestId: requestId,
      deviceId: deviceId,
      state: .disconnected,
      nativeCode: error == nil ? nil : "disconnect_error"
    )
    delegate?.bleManager(self, didChangeConnection: event)
    pendingDisconnects.removeValue(forKey: deviceId)?.completion(.success(event))
    pendingConnects.removeValue(forKey: deviceId)?.completion(.failure(error ?? BleManagerError.operationFailed("disconnected")))
  }
}

extension BleManager: CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    let deviceId = peripheral.identifier.uuidString
    if let error {
      pendingDiscoveries.removeValue(forKey: deviceId)?.completion(.failure(error))
      return
    }

    let services = peripheral.services ?? []
    guard !services.isEmpty else {
      completeDiscovery(for: peripheral)
      return
    }

    if var pending = pendingDiscoveries[deviceId] {
      pending.remainingServices = services.count
      pendingDiscoveries[deviceId] = pending
    }
    services.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverCharacteristicsFor service: CBService,
    error: Error?
  ) {
    let deviceId = peripheral.identifier.uuidString
    if let error {
      pendingDiscoveries.removeValue(forKey: deviceId)?.completion(.failure(error))
      return
    }

    guard var pending = pendingDiscoveries[deviceId] else {
      return
    }
    pending.remainingServices -= 1
    if pending.remainingServices <= 0 {
      pendingDiscoveries[deviceId] = pending
      completeDiscovery(for: peripheral)
    } else {
      pendingDiscoveries[deviceId] = pending
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    let deviceId = peripheral.identifier.uuidString
    let key = characteristicKey(deviceId, characteristic)
    if let pending = pendingReads.removeValue(forKey: key) {
      if let error {
        pending.completion(.failure(error))
        return
      }
      pending.completion(
        .success(
          BleReadResultDto(
            requestId: pending.requestId,
            deviceId: deviceId,
            serviceUuid: characteristic.service?.uuid.uuidString ?? "",
            characteristicUuid: characteristic.uuid.uuidString,
            payload: FlutterStandardTypedData(bytes: characteristic.value ?? Data())
          )
        )
      )
      return
    }

    if error == nil {
      delegate?.bleManager(
        self,
        didReceive: BleNotificationDto(
          deviceId: deviceId,
          serviceUuid: characteristic.service?.uuid.uuidString ?? "",
          characteristicUuid: characteristic.uuid.uuidString,
          payload: FlutterStandardTypedData(bytes: characteristic.value ?? Data())
        )
      )
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didWriteValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    let deviceId = peripheral.identifier.uuidString
    let key = characteristicKey(deviceId, characteristic)
    guard let pending = pendingWrites.removeValue(forKey: key) else {
      return
    }
    if let error {
      pending.completion(.failure(error))
      return
    }
    pending.completion(
      .success(
        BleWriteResultDto(
          requestId: pending.requestId,
          deviceId: deviceId,
          serviceUuid: characteristic.service?.uuid.uuidString ?? "",
          characteristicUuid: characteristic.uuid.uuidString,
          accepted: true,
          nativeCode: nil
        )
      )
    )
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateNotificationStateFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    let deviceId = peripheral.identifier.uuidString
    let key = characteristicKey(deviceId, characteristic)
    guard let pending = pendingNotifyChanges.removeValue(forKey: key) else {
      return
    }
    if let error {
      pending.completion(.failure(error))
      return
    }
    pending.completion(
      .success(
        BleWriteResultDto(
          requestId: pending.requestId,
          deviceId: deviceId,
          serviceUuid: characteristic.service?.uuid.uuidString ?? "",
          characteristicUuid: characteristic.uuid.uuidString,
          accepted: characteristic.isNotifying == pending.enabled,
          nativeCode: nil
        )
      )
    )
  }
}
