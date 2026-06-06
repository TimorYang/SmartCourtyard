import Foundation
import OSLog

final class BleLogger {
  private let subsystem = Bundle.main.bundleIdentifier ?? "com.flinx.flinx"
  private let category = "BLE"

  func info(
    _ operation: String,
    requestId: String? = nil,
    deviceId: String? = nil,
    state: String? = nil,
    nativeCode: String? = nil,
    durationMs: Int? = nil,
    payloadBytes: Int? = nil,
    details: String? = nil
  ) {
    log(
      level: .info,
      operation: operation,
      requestId: requestId,
      deviceId: deviceId,
      state: state,
      nativeCode: nativeCode,
      durationMs: durationMs,
      payloadBytes: payloadBytes,
      details: details
    )
  }

  func warning(
    _ operation: String,
    requestId: String? = nil,
    deviceId: String? = nil,
    state: String? = nil,
    nativeCode: String? = nil,
    durationMs: Int? = nil,
    payloadBytes: Int? = nil,
    details: String? = nil
  ) {
    log(
      level: .default,
      operation: operation,
      requestId: requestId,
      deviceId: deviceId,
      state: state,
      nativeCode: nativeCode,
      durationMs: durationMs,
      payloadBytes: payloadBytes,
      details: details
    )
  }

  func error(
    _ operation: String,
    requestId: String? = nil,
    deviceId: String? = nil,
    nativeCode: String? = nil,
    durationMs: Int? = nil,
    details: String? = nil
  ) {
    log(
      level: .error,
      operation: operation,
      requestId: requestId,
      deviceId: deviceId,
      state: nil,
      nativeCode: nativeCode,
      durationMs: durationMs,
      payloadBytes: nil,
      details: details
    )
  }

  private func log(
    level: OSLogType,
    operation: String,
    requestId: String?,
    deviceId: String?,
    state: String?,
    nativeCode: String?,
    durationMs: Int?,
    payloadBytes: Int?,
    details: String?
  ) {
    var parts = [
      "operation=\(operation)",
      "requestId=\(requestId ?? "-")",
      "deviceId=\(deviceId ?? "-")",
      "state=\(state ?? "-")",
      "nativeCode=\(nativeCode ?? "-")",
      "durationMs=\(durationMs.map(String.init) ?? "-")",
      "payloadBytes=\(payloadBytes.map(String.init) ?? "-")",
    ]
    if let details, !details.isEmpty {
      parts.append("details=\(details)")
    }
    let message = parts.joined(separator: " ")

    if #available(iOS 14.0, *) {
      let logger = Logger(subsystem: subsystem, category: category)
      switch level {
      case .error, .fault:
        logger.error("\(message, privacy: .public)")
      case .info, .debug:
        logger.info("\(message, privacy: .public)")
      default:
        logger.notice("\(message, privacy: .public)")
      }
    } else {
      os_log("%{public}@", log: OSLog(subsystem: subsystem, category: category), type: level, message)
    }
  }
}
