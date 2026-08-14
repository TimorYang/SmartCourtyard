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

  func testRemotePairingUsesControlCommandAndDedicatedResponse() throws {
    let start = HardwareBridge.remotePairingProtocolForTesting(start: true)
    let cancel = HardwareBridge.remotePairingProtocolForTesting(start: false)

    XCTAssertEqual(start.requestCommand, 0x0005)
    XCTAssertEqual(start.responseCommand, 0x0104)
    XCTAssertEqual(start.control, 0x1008)
    XCTAssertEqual(start.responseTimeout, 20)
    XCTAssertEqual(cancel.requestCommand, 0x0005)
    XCTAssertEqual(cancel.responseCommand, 0x0104)
    XCTAssertEqual(cancel.control, 0x1009)

    let key = Data((0..<16).map(UInt8.init))
    let frame = try XCTUnwrap(
      HardwareBridge.makeEncryptedFrameForTesting(
        sequence: 9,
        command: start.requestCommand,
        payload: Data([0x10, 0x08]),
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
    XCTAssertEqual(decoded.sequence, 9)
    XCTAssertEqual(decoded.command, 0x0005)
    XCTAssertEqual(decoded.data, Data([0x10, 0x08]))
  }

  func testRemotePairingMatchesOnlyExpectedResponseAndSequence() {
    XCTAssertTrue(
      HardwareBridge.matchesProvisioningResponseForTesting(
        expectedCommand: 0x0104,
        pendingSequence: 9,
        responseCommand: 0x0104,
        responseSequence: 9
      )
    )
    XCTAssertFalse(
      HardwareBridge.matchesProvisioningResponseForTesting(
        expectedCommand: 0x0104,
        pendingSequence: 9,
        responseCommand: 0x0005,
        responseSequence: 9
      )
    )
    XCTAssertFalse(
      HardwareBridge.matchesProvisioningResponseForTesting(
        expectedCommand: 0x0104,
        pendingSequence: 9,
        responseCommand: 0x0104,
        responseSequence: 10
      )
    )
  }

  func testRemotePairingResultMapping() {
    XCTAssertEqual(
      HardwareBridge.remotePairingStatusForTesting(resultCode: 0x06),
      .success
    )
    XCTAssertEqual(
      HardwareBridge.remotePairingStatusForTesting(resultCode: 0x05),
      .failure
    )
    XCTAssertEqual(
      HardwareBridge.remotePairingStatusForTesting(resultCode: 0x7F),
      .unknown
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

  func testParsesSafetyAccessoryListAndPreservesProtocolValues() throws {
    let accessories = try HardwareBridge.parseSafetyAccessoryListForTesting(
      Data([
        0x00, 0x07,
        0x01, 0x00, 0x00, 0x71, 0x01,
        0x02, 0x00, 0x00, 0x72, 0x0F,
        0x03, 0x00, 0x00, 0x73, 0x02,
        0x04, 0x00, 0x00, 0x74, 0x11,
        0x05, 0x00, 0x00, 0x75, 0x12,
        0x06, 0x00, 0x00, 0x76, 0x00,
        0x7F, 0x00, 0x00, 0x77, 0x55,
      ])
    )

    XCTAssertEqual(accessories.count, 7)
    XCTAssertEqual(accessories[0].serialNumber, 0x01000071)
    XCTAssertEqual(accessories[0].statusCode, 0x01)
    XCTAssertEqual(accessories[5].serialNumber, 0x06000076)
    XCTAssertEqual(accessories[5].statusCode, 0x00)
    XCTAssertEqual(accessories[6].serialNumber, 0x7F000077)
    XCTAssertEqual(accessories[6].statusCode, 0x55)
  }

  func testParsesEmptySafetyAccessoryList() throws {
    let accessories = try HardwareBridge.parseSafetyAccessoryListForTesting(
      Data([0x00, 0x00])
    )
    XCTAssertTrue(accessories.isEmpty)
  }

  func testRejectsTruncatedOrCountMismatchedSafetyAccessoryList() {
    XCTAssertThrowsError(
      try HardwareBridge.parseSafetyAccessoryListForTesting(Data([0x00]))
    )
    XCTAssertThrowsError(
      try HardwareBridge.parseSafetyAccessoryListForTesting(
        Data([0x00, 0x02, 0x01, 0x00, 0x00, 0x71, 0x01])
      )
    )
  }

  func testBuildsAndParsesSafetyAccessoryDeleteProtocol() throws {
    XCTAssertEqual(
      HardwareBridge.makeSafetyAccessoryDeletePayloadForTesting(
        serialNumber: 0x05000071
      ),
      Data([0x01, 0x05, 0x00, 0x00, 0x71])
    )
    let success = try HardwareBridge.parseSafetyAccessoryDeleteResultForTesting(
      Data([0x01, 0x00, 0x00, 0x00, 0x00])
    )
    XCTAssertTrue(success.success)
    XCTAssertEqual(success.reasonCode, 0)
    let failure = try HardwareBridge.parseSafetyAccessoryDeleteResultForTesting(
      Data([0xFF, 0x01, 0x02, 0x00, 0x04])
    )
    XCTAssertFalse(failure.success)
    XCTAssertEqual(failure.reasonCode, 0x01020004)
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
