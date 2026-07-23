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

}
