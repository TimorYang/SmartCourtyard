import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  func testEncryptedFrameUsesProvidedAesKey() throws {
    let key = Data((0..<16).map(UInt8.init))
    let wrongKey = Data((16..<32).map(UInt8.init))
    let frame = try XCTUnwrap(
      HardwareBridge.makeEncryptedFrameForTesting(
        sequence: 7,
        command: 0x0E03,
        payload: Data([0x00, 0xF1]),
        aesKey: key
      )
    )
    let cipher = frame.subdata(in: 5..<(frame.count - 3))
    let plaintext = try XCTUnwrap(
      HardwareBridge.decryptEcbForTesting(cipher, aesKey: key)
    )
    let decoded = try XCTUnwrap(
      HardwareBridge.parseDecryptedPayloadForTesting(plaintext)
    )

    XCTAssertEqual(decoded.sequence, 7)
    XCTAssertEqual(decoded.command, 0x0E03)
    XCTAssertEqual(decoded.data, Data([0x00, 0xF1]))
    let wrongDecoded = HardwareBridge.decryptEcbForTesting(cipher, aesKey: wrongKey)
      .flatMap(HardwareBridge.parseDecryptedPayloadForTesting)
    XCTAssertFalse(
      wrongDecoded?.sequence == 7 &&
        wrongDecoded?.command == 0x0E03 &&
        wrongDecoded?.data == Data([0x00, 0xF1])
    )
  }

  func testDetailedBlePayloadLoggingDefaultsToDisabled() {
    let logger = BleLogger()
    XCTAssertEqual(logger.payloadHex(Data([0x55, 0xAA])), "<native console logging disabled>")
    logger.setNativeConsoleLogging(enabled: true)
    XCTAssertEqual(logger.payloadHex(Data([0x55, 0xAA])), "55AA")
    XCTAssertEqual(
      logger.payloadHex(Data([0x55]), sensitive: true),
      "<redacted sensitive payload>"
    )
  }

  func testParsesGoldenActiveAttributeReport() throws {
    let plaintext = try XCTUnwrap(
      data(
        "030607020227006F70656E65725F42384638363231314139444300270200002703000027090127100027110727131E2714012715012716000F2717032718A1271901271AFFFF271B00271C0D271DF1271F0027200027210027220027230027250000272605272700272800272902272B03273500273B00273C00273D01"
      )
    )
    XCTAssertEqual(plaintext.count, 125)
    XCTAssertEqual(plaintext[0], 0x03)
    let decoded = try XCTUnwrap(
      HardwareBridge.parseDecryptedPayloadForTesting(plaintext)
    )
    XCTAssertEqual(decoded.sequence, 0x0607)
    XCTAssertEqual(decoded.command, 0x0202)

    let attributes = try HardwareBridge.parseDeviceAttributesForTesting(
      decoded.data
    )
    XCTAssertEqual(attributes.count, 32)
    let values = Dictionary(uniqueKeysWithValues: attributes.map { ($0.id, $0.value) })
    XCTAssertEqual(
      values[0x2700],
      "opener_B8F86211A9DC".data(using: .utf8)
    )
    XCTAssertEqual(values[0x2713], Data([0x1E]))
    XCTAssertEqual(values[0x2716], Data([0x00, 0x0F]))
    XCTAssertEqual(values[0x2725], Data([0x00, 0x00]))
    XCTAssertEqual(values[0x273D], Data([0x01]))
  }

  func testBuildsSingleAndMultipleAttributeWritePayloads() throws {
    let payload = try HardwareBridge.makeAttributeWritePayloadForTesting([
      (id: 0x2713, value: Data([0x1E])),
      (id: 0x2725, value: Data([0x00, 0x3C])),
    ])
    XCTAssertEqual(payload, Data([0x27, 0x13, 0x1E, 0x27, 0x25, 0x00, 0x3C]))
  }

  func testWifiProvisionPayloadUsesProtocolFieldOrder() throws {
    let payload = try HardwareBridge.makeWifiProvisionPayloadForTesting(
      ssid: "FLINX \"Guest\"",
      password: "p@ss\\word"
    )

    XCTAssertEqual(
      String(data: payload, encoding: .utf8),
      "{\"ssid\":\"FLINX \\\"Guest\\\"\",\"pwd\":\"p@ss\\\\word\"}"
    )
  }

  func testRejectsUnknownAndTruncatedAttributes() {
    XCTAssertThrowsError(
      try HardwareBridge.parseDeviceAttributesForTesting(
        Data([0x27, 0x04, 0x00])
      )
    )
    XCTAssertThrowsError(
      try HardwareBridge.parseDeviceAttributesForTesting(
        Data([0x27, 0x25, 0x00])
      )
    )
    XCTAssertThrowsError(
      try HardwareBridge.parseDeviceAttributesForTesting(
        Data([0x27, 0x00, 0x41])
      )
    )
  }

  private func data(_ hex: String) -> Data? {
    guard hex.count.isMultiple(of: 2) else { return nil }
    var result = Data()
    var index = hex.startIndex
    while index < hex.endIndex {
      let next = hex.index(index, offsetBy: 2)
      guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
      result.append(byte)
      index = next
    }
    return result
  }

}
