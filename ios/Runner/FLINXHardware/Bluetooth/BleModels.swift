import Foundation

struct BleScanFilter {
  let serviceUuids: [String]
  let namePrefix: String?
  let exactName: String?
  let allowDuplicates: Bool
}

struct BleDiscoveredDevice {
  let requestId: String
  let scanSessionId: String
  let id: String
  let name: String?
  let rssi: Int
  let advertisementServiceUuids: [String]
  let manufacturerData: Data
  let seenAtMillis: Int64
}

enum BleConnectionState {
  case disconnected
  case connecting
  case connected
}

struct BleConnectionEvent {
  let requestId: String
  let deviceId: String
  let state: BleConnectionState
  let nativeCode: String?
}

struct BleAuthenticationResult {
  let requestId: String
  let deviceId: String
  let authenticated: Bool
  let bindingState: Int64?
  let nativeCode: String?
}

struct WifiScanResult {
  let requestId: String
  let deviceId: String
  let ssids: [String]
}

struct WifiProvisionResult {
  let requestId: String
  let deviceId: String
  let ssid: String
  let success: Bool
  let nativeCode: String?
}

struct BleCharacteristic {
  let serviceUuid: String
  let characteristicUuid: String
  let canRead: Bool
  let canWriteWithResponse: Bool
  let canWriteWithoutResponse: Bool
  let canNotify: Bool
}

struct BleService {
  let serviceUuid: String
  let characteristics: [BleCharacteristic]
}

struct BleServices {
  let requestId: String
  let deviceId: String
  let services: [BleService]
}

struct BleReadResult {
  let requestId: String
  let deviceId: String
  let serviceUuid: String
  let characteristicUuid: String
  let payload: Data
}

enum BleWriteType {
  case withResponse
  case withoutResponse
}

struct BleWriteResult {
  let requestId: String
  let deviceId: String
  let serviceUuid: String
  let characteristicUuid: String
  let accepted: Bool
  let nativeCode: String?
}

struct BleNotification {
  let requestId: String?
  let deviceId: String
  let serviceUuid: String
  let characteristicUuid: String
  let payload: Data
  let timestampMillis: Int64
  let sequenceNumber: Int64
}

struct BleNativeError {
  let code: String
  let domainCode: String
  let message: String?
  let requestId: String?
  let deviceId: String?
  let retryable: Bool
  let timestampMillis: Int64
}

enum BleManagerError: Error {
  case bluetoothUnavailable
  case bluetoothUnauthorized
  case deviceNotFound(String)
  case peripheralUnavailable(String)
  case serviceNotFound(String)
  case characteristicNotFound(String)
  case operationInProgress(String)
  case operationTimeout(String)
  case bluetoothDisconnected(String)
  case operationFailed(String)

  var nativeCode: String {
    switch self {
    case .bluetoothUnavailable:
      return "bluetooth_unavailable"
    case .bluetoothUnauthorized:
      return "bluetooth_unauthorized"
    case .deviceNotFound:
      return "device_not_found"
    case .peripheralUnavailable:
      return "peripheral_unavailable"
    case .serviceNotFound:
      return "service_not_found"
    case .characteristicNotFound:
      return "characteristic_not_found"
    case .operationInProgress:
      return "operation_in_progress"
    case .operationTimeout:
      return "operation_timeout"
    case .bluetoothDisconnected:
      return "bluetooth_disconnected"
    case .operationFailed(let code):
      return code
    }
  }

  var domainCode: String {
    switch self {
    case .bluetoothUnavailable:
      return "bluetoothUnavailable"
    case .bluetoothUnauthorized:
      return "permissionDenied"
    case .peripheralUnavailable, .bluetoothDisconnected:
      return "bluetoothDisconnected"
    case .operationInProgress:
      return "deviceBusy"
    case .operationTimeout:
      return "commandTimeout"
    default:
      return "unknown"
    }
  }

  var retryable: Bool {
    switch self {
    case .bluetoothUnavailable, .bluetoothUnauthorized:
      return false
    case .deviceNotFound, .peripheralUnavailable, .serviceNotFound, .characteristicNotFound:
      return false
    case .operationInProgress:
      return true
    case .operationTimeout, .bluetoothDisconnected, .operationFailed:
      return true
    }
  }
}

extension BleManagerError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .bluetoothUnavailable:
      return "Bluetooth is not powered on."
    case .bluetoothUnauthorized:
      return "Bluetooth permission is not granted."
    case .deviceNotFound(let deviceId):
      return "BLE device was not discovered: \(deviceId)"
    case .peripheralUnavailable(let deviceId):
      return "BLE device is not connected: \(deviceId)"
    case .serviceNotFound(let serviceUuid):
      return "BLE service was not discovered: \(serviceUuid)"
    case .characteristicNotFound(let characteristicUuid):
      return "BLE characteristic was not discovered: \(characteristicUuid)"
    case .operationInProgress(let operation):
      return "BLE operation is already in progress: \(operation)"
    case .operationTimeout(let operation):
      return "BLE operation timed out: \(operation)"
    case .bluetoothDisconnected(let deviceId):
      return "BLE device disconnected: \(deviceId)"
    case .operationFailed(let code):
      return "BLE operation failed: \(code)"
    }
  }
}

func bleTimestampMillis() -> Int64 {
  Int64((Date().timeIntervalSince1970 * 1000).rounded())
}
