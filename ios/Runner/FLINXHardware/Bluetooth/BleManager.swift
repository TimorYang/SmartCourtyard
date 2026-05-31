import CoreBluetooth
import Foundation

protocol BleManagerDelegate: AnyObject {
  func bleManager(_ manager: BleManager, didDiscover device: BleDiscoveredDevice)
  func bleManager(_ manager: BleManager, didChangeConnection event: BleConnectionEvent)
  func bleManager(_ manager: BleManager, didReceive notification: BleNotification)
  func bleManager(_ manager: BleManager, didReceive error: BleNativeError)
}

final class BleManager: NSObject {
  weak var delegate: BleManagerDelegate?

  private let operationTimeoutSeconds: TimeInterval = 15
  private let logger: BleLogger
  private lazy var centralManager = CBCentralManager(delegate: self, queue: .main)

  private var peripheralsById: [String: CBPeripheral] = [:]
  private var currentScan: ScanSession?
  private var notificationSequence: Int64 = 0

  private var pendingConnects:
    [String: PendingOperation<BleConnectionEvent>] = [:]
  private var pendingDisconnects:
    [String: PendingOperation<BleConnectionEvent>] = [:]
  private var pendingDiscoveries:
    [String: PendingDiscovery] = [:]
  private var pendingReads:
    [String: PendingOperation<BleReadResult>] = [:]
  private var pendingWrites:
    [String: PendingOperation<BleWriteResult>] = [:]
  private var pendingNotifyChanges:
    [String: PendingNotifyChange] = [:]

  init(logger: BleLogger = BleLogger()) {
    self.logger = logger
    super.init()
  }

  func bluetoothGranted() -> Bool {
    if #available(iOS 13.1, *) {
      return CBCentralManager.authorization == .allowedAlways
    }
    return true
  }

  func prepareForPermissionRequest() {
    _ = centralManager.state
  }

  func startScan(requestId: String, filter: BleScanFilter) throws {
    try ensureBluetoothReady(requestId: requestId)
    let session = ScanSession(requestId: requestId, filter: filter)
    currentScan = session

    let serviceUuids = normalizedUuids(filter.serviceUuids).map(CBUUID.init(string:))
    logger.info(
      "scan_start",
      requestId: requestId,
      state: "started",
      nativeCode: session.sessionId
    )
    centralManager.scanForPeripherals(
      withServices: serviceUuids.isEmpty ? nil : serviceUuids,
      options: [CBCentralManagerScanOptionAllowDuplicatesKey: filter.allowDuplicates]
    )
  }

  func stopScan(requestId: String) {
    centralManager.stopScan()
    let sessionId = currentScan?.sessionId
    currentScan = nil
    logger.info("scan_stop", requestId: requestId, state: "stopped", nativeCode: sessionId)
  }

  func connect(
    requestId: String,
    deviceId: String,
    completion: @escaping (Result<BleConnectionEvent, Error>) -> Void
  ) {
    guard pendingConnects[deviceId] == nil else {
      completeWithError(.operationInProgress("connect"), requestId: requestId, deviceId: deviceId, completion: completion)
      return
    }
    guard let peripheral = peripheralsById[deviceId] else {
      completeWithError(.deviceNotFound(deviceId), requestId: requestId, deviceId: deviceId, completion: completion)
      return
    }

    peripheral.delegate = self
    pendingConnects[deviceId] = makePending(
      operation: "connect",
      requestId: requestId,
      deviceId: deviceId,
      completion: completion
    )
    logger.info("connect", requestId: requestId, deviceId: deviceId, state: "started")
    emitConnection(requestId: requestId, deviceId: deviceId, state: .connecting)
    centralManager.connect(peripheral)
  }

  func disconnect(
    requestId: String,
    deviceId: String,
    completion: @escaping (Result<BleConnectionEvent, Error>) -> Void
  ) {
    guard pendingDisconnects[deviceId] == nil else {
      completeWithError(.operationInProgress("disconnect"), requestId: requestId, deviceId: deviceId, completion: completion)
      return
    }
    guard let peripheral = peripheralsById[deviceId] else {
      completeWithError(.deviceNotFound(deviceId), requestId: requestId, deviceId: deviceId, completion: completion)
      return
    }

    if peripheral.state == .disconnected {
      let event = BleConnectionEvent(
        requestId: requestId,
        deviceId: deviceId,
        state: .disconnected,
        nativeCode: nil
      )
      delegate?.bleManager(self, didChangeConnection: event)
      completion(.success(event))
      return
    }

    pendingDisconnects[deviceId] = makePending(
      operation: "disconnect",
      requestId: requestId,
      deviceId: deviceId,
      completion: completion
    )
    logger.info("disconnect", requestId: requestId, deviceId: deviceId, state: "started")
    centralManager.cancelPeripheralConnection(peripheral)
  }

  func discoverServices(
    requestId: String,
    deviceId: String,
    completion: @escaping (Result<BleServices, Error>) -> Void
  ) {
    guard pendingDiscoveries[deviceId] == nil else {
      completeWithError(.operationInProgress("discover_services"), requestId: requestId, deviceId: deviceId, completion: completion)
      return
    }
    guard let peripheral = connectedPeripheral(deviceId: deviceId, requestId: requestId, completion: completion) else {
      return
    }

    peripheral.delegate = self
    pendingDiscoveries[deviceId] = PendingDiscovery(
      operation: "discover_services",
      requestId: requestId,
      deviceId: deviceId,
      startedAt: Date(),
      remainingServices: 0,
      timeout: scheduleTimeout(deviceId: deviceId, operation: "discover_services") { [weak self] in
        guard let self, let pending = self.pendingDiscoveries.removeValue(forKey: deviceId) else { return }
        pending.timeout.cancel()
        let error = BleManagerError.operationTimeout("discover_services")
        self.emitNativeError(error, requestId: requestId, deviceId: deviceId)
        pending.completion(.failure(error))
      },
      completion: completion
    )
    logger.info("discover_services", requestId: requestId, deviceId: deviceId, state: "started")
    peripheral.discoverServices(nil)
  }

  func readCharacteristic(
    requestId: String,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    completion: @escaping (Result<BleReadResult, Error>) -> Void
  ) {
    guard let peripheral = connectedPeripheral(deviceId: deviceId, requestId: requestId, completion: completion) else {
      return
    }
    guard let characteristic = findCharacteristic(
      peripheral: peripheral,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid
    ) else {
      completeWithError(.characteristicNotFound(characteristicUuid), requestId: requestId, deviceId: deviceId, completion: completion)
      return
    }

    let key = characteristicKey(deviceId, characteristic)
    guard pendingReads[key] == nil else {
      completeWithError(.operationInProgress("read_characteristic"), requestId: requestId, deviceId: deviceId, completion: completion)
      return
    }

    pendingReads[key] = makePending(
      operation: "read_characteristic",
      requestId: requestId,
      deviceId: deviceId,
      completion: completion
    )
    logger.info("read_characteristic", requestId: requestId, deviceId: deviceId, state: "started")
    peripheral.readValue(for: characteristic)
  }

  func writeCharacteristic(
    requestId: String,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    payload: Data,
    writeType: BleWriteType,
    completion: @escaping (Result<BleWriteResult, Error>) -> Void
  ) {
    guard let peripheral = connectedPeripheral(deviceId: deviceId, requestId: requestId, completion: completion) else {
      return
    }
    guard let characteristic = findCharacteristic(
      peripheral: peripheral,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid
    ) else {
      completeWithError(.characteristicNotFound(characteristicUuid), requestId: requestId, deviceId: deviceId, completion: completion)
      return
    }

    let cbWriteType: CBCharacteristicWriteType =
      writeType == .withoutResponse ? .withoutResponse : .withResponse
    let key = characteristicKey(deviceId, characteristic)
    if cbWriteType == .withResponse {
      guard pendingWrites[key] == nil else {
        completeWithError(.operationInProgress("write_characteristic"), requestId: requestId, deviceId: deviceId, completion: completion)
        return
      }
      pendingWrites[key] = makePending(
        operation: "write_characteristic",
        requestId: requestId,
        deviceId: deviceId,
        completion: completion
      )
    }

    logger.info(
      "write_characteristic",
      requestId: requestId,
      deviceId: deviceId,
      state: "started",
      payloadBytes: payload.count
    )
    peripheral.writeValue(payload, for: characteristic, type: cbWriteType)

    if cbWriteType == .withoutResponse {
      completion(
        .success(
          BleWriteResult(
            requestId: requestId,
            deviceId: deviceId,
            serviceUuid: serviceUuid,
            characteristicUuid: characteristicUuid,
            accepted: true,
            nativeCode: nil
          )
        )
      )
    }
  }

  func setCharacteristicNotify(
    requestId: String,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    enabled: Bool,
    completion: @escaping (Result<BleWriteResult, Error>) -> Void
  ) {
    guard let peripheral = connectedPeripheral(deviceId: deviceId, requestId: requestId, completion: completion) else {
      return
    }
    guard let characteristic = findCharacteristic(
      peripheral: peripheral,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid
    ) else {
      completeWithError(.characteristicNotFound(characteristicUuid), requestId: requestId, deviceId: deviceId, completion: completion)
      return
    }

    let key = characteristicKey(deviceId, characteristic)
    guard pendingNotifyChanges[key] == nil else {
      completeWithError(.operationInProgress("set_notify"), requestId: requestId, deviceId: deviceId, completion: completion)
      return
    }

    pendingNotifyChanges[key] = PendingNotifyChange(
      operation: "set_notify",
      requestId: requestId,
      deviceId: deviceId,
      startedAt: Date(),
      enabled: enabled,
      timeout: scheduleTimeout(deviceId: deviceId, operation: "set_notify") { [weak self] in
        guard let self, let pending = self.pendingNotifyChanges.removeValue(forKey: key) else { return }
        pending.timeout.cancel()
        let error = BleManagerError.operationTimeout("set_notify")
        self.emitNativeError(error, requestId: requestId, deviceId: deviceId)
        pending.completion(.failure(error))
      },
      completion: completion
    )
    logger.info("set_notify", requestId: requestId, deviceId: deviceId, state: enabled ? "enable" : "disable")
    peripheral.setNotifyValue(enabled, for: characteristic)
  }

  private func ensureBluetoothReady(requestId: String) throws {
    if #available(iOS 13.1, *), CBCentralManager.authorization == .denied {
      let error = BleManagerError.bluetoothUnauthorized
      emitNativeError(error, requestId: requestId, deviceId: nil)
      throw error
    }
    guard centralManager.state == .poweredOn else {
      let error = BleManagerError.bluetoothUnavailable
      emitNativeError(error, requestId: requestId, deviceId: nil)
      throw error
    }
  }

  private func connectedPeripheral<T>(
    deviceId: String,
    requestId: String,
    completion: (Result<T, Error>) -> Void
  ) -> CBPeripheral? {
    guard let peripheral = peripheralsById[deviceId] else {
      completeWithError(.deviceNotFound(deviceId), requestId: requestId, deviceId: deviceId, completion: completion)
      return nil
    }
    guard peripheral.state == .connected else {
      completeWithError(.peripheralUnavailable(deviceId), requestId: requestId, deviceId: deviceId, completion: completion)
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
    pending.timeout.cancel()

    let services = peripheral.services?.map { service in
      BleService(
        serviceUuid: service.uuid.uuidString.uppercased(),
        characteristics: (service.characteristics ?? []).map { characteristic in
          BleCharacteristic(
            serviceUuid: service.uuid.uuidString.uppercased(),
            characteristicUuid: characteristic.uuid.uuidString.uppercased(),
            canRead: characteristic.properties.contains(.read),
            canWriteWithResponse: characteristic.properties.contains(.write),
            canWriteWithoutResponse: characteristic.properties.contains(.writeWithoutResponse),
            canNotify: characteristic.properties.contains(.notify)
              || characteristic.properties.contains(.indicate)
          )
        }
      )
    } ?? []

    logger.info(
      pending.operation,
      requestId: pending.requestId,
      deviceId: deviceId,
      state: "success",
      durationMs: pending.durationMs
    )
    pending.completion(
      .success(
        BleServices(
          requestId: pending.requestId,
          deviceId: deviceId,
          services: services
        )
      )
    )
  }

  private func characteristicKey(_ deviceId: String, _ characteristic: CBCharacteristic) -> String {
    let serviceUuid = characteristic.service?.uuid.uuidString.uppercased() ?? ""
    return "\(deviceId)|\(serviceUuid)|\(characteristic.uuid.uuidString.uppercased())"
  }

  private func emitConnection(
    requestId: String,
    deviceId: String,
    state: BleConnectionState,
    nativeCode: String? = nil
  ) {
    let event = BleConnectionEvent(
      requestId: requestId,
      deviceId: deviceId,
      state: state,
      nativeCode: nativeCode
    )
    delegate?.bleManager(self, didChangeConnection: event)
  }

  private func emitNativeError(
    _ error: BleManagerError,
    requestId: String?,
    deviceId: String?
  ) {
    logger.error("native_error", requestId: requestId, deviceId: deviceId, nativeCode: error.nativeCode)
    delegate?.bleManager(
      self,
      didReceive: BleNativeError(
        code: error.nativeCode,
        domainCode: error.domainCode,
        message: error.errorDescription,
        requestId: requestId,
        deviceId: deviceId,
        retryable: error.retryable,
        timestampMillis: bleTimestampMillis()
      )
    )
  }

  private func completeWithError<T>(
    _ error: BleManagerError,
    requestId: String,
    deviceId: String?,
    completion: (Result<T, Error>) -> Void
  ) {
    emitNativeError(error, requestId: requestId, deviceId: deviceId)
    completion(.failure(error))
  }

  private func makePending<T>(
    operation: String,
    requestId: String,
    deviceId: String,
    completion: @escaping (Result<T, Error>) -> Void
  ) -> PendingOperation<T> {
    PendingOperation(
      operation: operation,
      requestId: requestId,
      deviceId: deviceId,
      startedAt: Date(),
      timeout: scheduleTimeout(deviceId: deviceId, operation: operation) { [weak self] in
        self?.timeoutPending(operation: operation, requestId: requestId, deviceId: deviceId)
      },
      completion: completion
    )
  }

  private func scheduleTimeout(
    deviceId: String,
    operation: String,
    handler: @escaping () -> Void
  ) -> DispatchWorkItem {
    let item = DispatchWorkItem(block: handler)
    DispatchQueue.main.asyncAfter(deadline: .now() + operationTimeoutSeconds, execute: item)
    return item
  }

  private func timeoutPending(operation: String, requestId: String, deviceId: String) {
    let error = BleManagerError.operationTimeout(operation)
    switch operation {
    case "connect":
      if let pending = pendingConnects.removeValue(forKey: deviceId) {
        pending.timeout.cancel()
        emitNativeError(error, requestId: requestId, deviceId: deviceId)
        pending.completion(.failure(error))
      }
    case "disconnect":
      if let pending = pendingDisconnects.removeValue(forKey: deviceId) {
        pending.timeout.cancel()
        emitNativeError(error, requestId: requestId, deviceId: deviceId)
        pending.completion(.failure(error))
      }
    default:
      break
    }
  }

  private func failPendingOperations(for deviceId: String, error: BleManagerError) {
    pendingDiscoveries.removeValue(forKey: deviceId).map { pending in
      pending.timeout.cancel()
      pending.completion(.failure(error))
    }

    failCharacteristicPending(&pendingReads, deviceId: deviceId, error: error)
    failCharacteristicPending(&pendingWrites, deviceId: deviceId, error: error)

    for key in pendingNotifyChanges.keys.filter({ $0.hasPrefix("\(deviceId)|") }) {
      if let pending = pendingNotifyChanges.removeValue(forKey: key) {
        pending.timeout.cancel()
        pending.completion(.failure(error))
      }
    }
  }

  private func failCharacteristicPending<T>(
    _ pendingMap: inout [String: PendingOperation<T>],
    deviceId: String,
    error: BleManagerError
  ) {
    for key in pendingMap.keys.filter({ $0.hasPrefix("\(deviceId)|") }) {
      if let pending = pendingMap.removeValue(forKey: key) {
        pending.timeout.cancel()
        pending.completion(.failure(error))
      }
    }
  }

  private func normalizedUuids(_ uuids: [String]) -> [String] {
    Array(Set(uuids.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
      .filter { !$0.isEmpty })).sorted()
  }
}

extension BleManager: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state != .poweredOn {
      emitNativeError(.bluetoothUnavailable, requestId: currentScan?.requestId, deviceId: nil)
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    guard var scan = currentScan else {
      return
    }

    let rawName = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
    let name = rawName?.trimmingCharacters(in: .whitespacesAndNewlines)
    let normalizedName = name?.isEmpty == true ? nil : name
    if let exactName = scan.filter.exactName, normalizedName != exactName {
      return
    }
    if let namePrefix = scan.filter.namePrefix, normalizedName?.hasPrefix(namePrefix) != true {
      return
    }

    let deviceId = peripheral.identifier.uuidString
    peripheralsById[deviceId] = peripheral
    peripheral.delegate = self

    let serviceUuids = normalizedUuids(
      (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.map(\.uuidString) ?? []
    )
    let manufacturerData =
      advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data ?? Data()
    let previous = scan.devices[deviceId]
    let rssi = previous.map { Int((Double($0.rssi) * 0.7 + Double(RSSI.intValue) * 0.3).rounded()) }
      ?? RSSI.intValue
    let device = BleDiscoveredDevice(
      requestId: scan.requestId,
      scanSessionId: scan.sessionId,
      id: deviceId,
      name: normalizedName,
      rssi: rssi,
      advertisementServiceUuids: serviceUuids,
      manufacturerData: manufacturerData,
      seenAtMillis: bleTimestampMillis()
    )

    scan.devices[deviceId] = device
    currentScan = scan

    if !scan.filter.allowDuplicates, let previous, !shouldEmitScanUpdate(previous: previous, next: device) {
      return
    }

    logger.info(
      "scan_result",
      requestId: scan.requestId,
      deviceId: deviceId,
      nativeCode: scan.sessionId,
      payloadBytes: manufacturerData.count
    )
    delegate?.bleManager(self, didDiscover: device)
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    let deviceId = peripheral.identifier.uuidString
    guard let pending = pendingConnects.removeValue(forKey: deviceId) else {
      emitConnection(requestId: "", deviceId: deviceId, state: .connected)
      return
    }
    pending.timeout.cancel()
    let event = BleConnectionEvent(
      requestId: pending.requestId,
      deviceId: deviceId,
      state: .connected,
      nativeCode: nil
    )
    logger.info(pending.operation, requestId: pending.requestId, deviceId: deviceId, state: "success", durationMs: pending.durationMs)
    delegate?.bleManager(self, didChangeConnection: event)
    pending.completion(.success(event))
  }

  func centralManager(
    _ central: CBCentralManager,
    didFailToConnect peripheral: CBPeripheral,
    error: Error?
  ) {
    let deviceId = peripheral.identifier.uuidString
    let pending = pendingConnects.removeValue(forKey: deviceId)
    pending?.timeout.cancel()
    let managerError = BleManagerError.operationFailed("connect_failed")
    emitNativeError(managerError, requestId: pending?.requestId, deviceId: deviceId)
    pending?.completion(.failure(error ?? managerError))
  }

  func centralManager(
    _ central: CBCentralManager,
    didDisconnectPeripheral peripheral: CBPeripheral,
    error: Error?
  ) {
    let deviceId = peripheral.identifier.uuidString
    let pendingDisconnect = pendingDisconnects.removeValue(forKey: deviceId)
    let pendingConnect = pendingConnects.removeValue(forKey: deviceId)
    pendingDisconnect?.timeout.cancel()
    pendingConnect?.timeout.cancel()

    let requestId = pendingDisconnect?.requestId ?? pendingConnect?.requestId ?? "native-disconnect-\(bleTimestampMillis())"
    let nativeCode = error == nil ? nil : "disconnect_error"
    let event = BleConnectionEvent(
      requestId: requestId,
      deviceId: deviceId,
      state: .disconnected,
      nativeCode: nativeCode
    )
    logger.warning("disconnect_event", requestId: requestId, deviceId: deviceId, state: "disconnected", nativeCode: nativeCode)
    delegate?.bleManager(self, didChangeConnection: event)

    pendingDisconnect?.completion(.success(event))
    pendingConnect?.completion(.failure(error ?? BleManagerError.bluetoothDisconnected(deviceId)))

    let disconnectError = BleManagerError.bluetoothDisconnected(deviceId)
    failPendingOperations(for: deviceId, error: disconnectError)
    if error != nil {
      emitNativeError(disconnectError, requestId: requestId, deviceId: deviceId)
    }
  }

  private func shouldEmitScanUpdate(previous: BleDiscoveredDevice, next: BleDiscoveredDevice) -> Bool {
    abs(previous.rssi - next.rssi) >= 8
      || previous.name != next.name
      || previous.advertisementServiceUuids != next.advertisementServiceUuids
      || previous.manufacturerData != next.manufacturerData
  }
}

extension BleManager: CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    let deviceId = peripheral.identifier.uuidString
    if let error {
      let pending = pendingDiscoveries.removeValue(forKey: deviceId)
      pending?.timeout.cancel()
      pending?.completion(.failure(error))
      emitNativeError(.operationFailed("discover_services_failed"), requestId: pending?.requestId, deviceId: deviceId)
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
      let pending = pendingDiscoveries.removeValue(forKey: deviceId)
      pending?.timeout.cancel()
      pending?.completion(.failure(error))
      emitNativeError(.operationFailed("discover_characteristics_failed"), requestId: pending?.requestId, deviceId: deviceId)
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
      pending.timeout.cancel()
      if let error {
        emitNativeError(.operationFailed("read_characteristic_failed"), requestId: pending.requestId, deviceId: deviceId)
        pending.completion(.failure(error))
        return
      }
      logger.info(
        pending.operation,
        requestId: pending.requestId,
        deviceId: deviceId,
        state: "success",
        durationMs: pending.durationMs,
        payloadBytes: characteristic.value?.count ?? 0
      )
      pending.completion(
        .success(
          BleReadResult(
            requestId: pending.requestId,
            deviceId: deviceId,
            serviceUuid: characteristic.service?.uuid.uuidString.uppercased() ?? "",
            characteristicUuid: characteristic.uuid.uuidString.uppercased(),
            payload: characteristic.value ?? Data()
          )
        )
      )
      return
    }

    if error == nil {
      notificationSequence += 1
      delegate?.bleManager(
        self,
        didReceive: BleNotification(
          requestId: nil,
          deviceId: deviceId,
          serviceUuid: characteristic.service?.uuid.uuidString.uppercased() ?? "",
          characteristicUuid: characteristic.uuid.uuidString.uppercased(),
          payload: characteristic.value ?? Data(),
          timestampMillis: bleTimestampMillis(),
          sequenceNumber: notificationSequence
        )
      )
      logger.info("notification", deviceId: deviceId, payloadBytes: characteristic.value?.count ?? 0)
    } else {
      emitNativeError(.operationFailed("notification_failed"), requestId: nil, deviceId: deviceId)
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
    pending.timeout.cancel()
    if let error {
      emitNativeError(.operationFailed("write_characteristic_failed"), requestId: pending.requestId, deviceId: deviceId)
      pending.completion(.failure(error))
      return
    }
    logger.info(pending.operation, requestId: pending.requestId, deviceId: deviceId, state: "success", durationMs: pending.durationMs)
    pending.completion(
      .success(
        BleWriteResult(
          requestId: pending.requestId,
          deviceId: deviceId,
          serviceUuid: characteristic.service?.uuid.uuidString.uppercased() ?? "",
          characteristicUuid: characteristic.uuid.uuidString.uppercased(),
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
    pending.timeout.cancel()
    if let error {
      emitNativeError(.operationFailed("set_notify_failed"), requestId: pending.requestId, deviceId: deviceId)
      pending.completion(.failure(error))
      return
    }
    logger.info(pending.operation, requestId: pending.requestId, deviceId: deviceId, state: "success", durationMs: pending.durationMs)
    pending.completion(
      .success(
        BleWriteResult(
          requestId: pending.requestId,
          deviceId: deviceId,
          serviceUuid: characteristic.service?.uuid.uuidString.uppercased() ?? "",
          characteristicUuid: characteristic.uuid.uuidString.uppercased(),
          accepted: characteristic.isNotifying == pending.enabled,
          nativeCode: nil
        )
      )
    )
  }
}

private struct ScanSession {
  let requestId: String
  let sessionId: String
  let filter: BleScanFilter
  var devices: [String: BleDiscoveredDevice]

  init(requestId: String, filter: BleScanFilter) {
    self.requestId = requestId
    self.sessionId = "\(requestId)-\(UUID().uuidString)"
    self.filter = filter
    self.devices = [:]
  }
}

private struct PendingOperation<T> {
  let operation: String
  let requestId: String
  let deviceId: String
  let startedAt: Date
  let timeout: DispatchWorkItem
  let completion: (Result<T, Error>) -> Void

  var durationMs: Int {
    Int(Date().timeIntervalSince(startedAt) * 1000)
  }
}

private struct PendingDiscovery {
  let operation: String
  let requestId: String
  let deviceId: String
  let startedAt: Date
  var remainingServices: Int
  let timeout: DispatchWorkItem
  let completion: (Result<BleServices, Error>) -> Void

  var durationMs: Int {
    Int(Date().timeIntervalSince(startedAt) * 1000)
  }
}

private struct PendingNotifyChange {
  let operation: String
  let requestId: String
  let deviceId: String
  let startedAt: Date
  let enabled: Bool
  let timeout: DispatchWorkItem
  let completion: (Result<BleWriteResult, Error>) -> Void

  var durationMs: Int {
    Int(Date().timeIntervalSince(startedAt) * 1000)
  }
}
