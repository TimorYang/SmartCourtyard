package com.flinx.flinx.flinxhardware.protocol

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class DeviceBleProtocolConfigTest {
  private val correctKey = "00112233445566778899AABBCCDDEEFF"
  private val wrongKey = "FFEEDDCCBBAA99887766554433221100"

  @Test
  fun `encrypted response matches only the server provided key`() {
    val response = DeviceBleProtocolConfig.buildEncryptedFrame(
      frameType = DeviceBleProtocolConfig.frameTypeResponse,
      sequence = 7,
      command = DeviceBleProtocolConfig.commandAuthenticate,
      data = byteArrayOf(0x00, 0xF1.toByte()),
      aesKeyHex = correctKey,
    )

    val decoded = DeviceBleProtocolConfig.decodeExpectedEncryptedResponse(
      payload = response,
      aesKeyHex = correctKey,
      expectedSequence = 7,
      expectedCommand = DeviceBleProtocolConfig.commandAuthenticate,
    )
    val wrongKeyResult = DeviceBleProtocolConfig.decodeExpectedEncryptedResponse(
      payload = response,
      aesKeyHex = wrongKey,
      expectedSequence = 7,
      expectedCommand = DeviceBleProtocolConfig.commandAuthenticate,
    )

    assertEquals(DeviceBleDecodeStatus.MATCHED, decoded.status)
    assertEquals(DeviceBleProtocolConfig.commandAuthenticate, decoded.frame?.command)
    assertEquals(DeviceBleDecodeStatus.DECRYPT_FAILED, wrongKeyResult.status)
  }

  @Test
  fun `different server keys produce different authentication frames`() {
    val first = DeviceBleProtocolConfig.buildAuthenticationFrame(
      sequence = 1,
      utcTimestampSeconds = 1_700_000_000,
      aesKeyHex = correctKey,
    )
    val second = DeviceBleProtocolConfig.buildAuthenticationFrame(
      sequence = 1,
      utcTimestampSeconds = 1_700_000_000,
      aesKeyHex = wrongKey,
    )

    assertNotEquals(DeviceBleProtocolConfig.toHex(first), DeviceBleProtocolConfig.toHex(second))
    assertTrue(DeviceBleProtocolConfig.hasValidEnvelope(first))
    assertTrue(DeviceBleProtocolConfig.hasValidEnvelope(second))
  }
}
