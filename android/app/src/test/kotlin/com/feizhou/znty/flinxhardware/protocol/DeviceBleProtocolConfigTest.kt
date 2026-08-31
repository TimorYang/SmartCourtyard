package com.feizhou.znty.flinxhardware.protocol

import org.junit.Assert.assertEquals
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertFalse
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

  @Test
  fun `remote pairing uses control command and two byte controls`() {
    val controls = listOf(
      DeviceBleProtocolConfig.controlRemotePairingStart to byteArrayOf(0x10, 0x08),
      DeviceBleProtocolConfig.controlRemotePairingCancel to byteArrayOf(0x10, 0x09),
    )

    controls.forEach { (control, expectedData) ->
      val packet = DeviceBleProtocolConfig.buildEncryptedCommandFrame(
        sequence = 9,
        command = DeviceBleProtocolConfig.commandControlDoor,
        aesKeyHex = correctKey,
        data = byteArrayOf((control shr 8).toByte(), control.toByte()),
      )
      val encryptedPayload = packet.copyOfRange(5, packet.size - 3)
      val plaintext = DeviceBleProtocolConfig.tryDecryptAesEcbPkcs7(
        encryptedPayload,
        DeviceBleProtocolConfig.candidateAesKeys(correctKey).single().keyBytes,
      )
      val decoded = DeviceBleProtocolConfig.parseDecryptedPayload(
        requireNotNull(plaintext),
        DeviceBleProtocolConfig.cryptoAes128,
      )

      requireNotNull(decoded)
      assertEquals(DeviceBleProtocolConfig.frameTypeRequest, decoded.frameType)
      assertEquals(9, decoded.sequence)
      assertEquals(DeviceBleProtocolConfig.commandControlDoor, decoded.command)
      assertArrayEquals(expectedData, decoded.data)
    }

    assertEquals(0x0104, DeviceBleProtocolConfig.commandRemotePairingResponse)
    assertEquals(0x1009, DeviceBleProtocolConfig.controlRemotePairingCancel)
    assertEquals(20_000L, DeviceBleProtocolConfig.remotePairingResponseTimeoutMillis)
  }

  @Test
  fun `remote pairing result maps success failure and unknown`() {
    assertEquals(
      DeviceRemotePairingResult.SUCCESS,
      DeviceBleProtocolConfig.remotePairingResult(0x06),
    )
    assertEquals(
      DeviceRemotePairingResult.FAILURE,
      DeviceBleProtocolConfig.remotePairingResult(0x05),
    )
    assertEquals(
      DeviceRemotePairingResult.UNKNOWN,
      DeviceBleProtocolConfig.remotePairingResult(0x7F),
    )
  }

  @Test
  fun `door open reminder uses command 0x0E09 and one byte duration`() {
    assertEquals(0x0E09, DeviceBleProtocolConfig.commandDoorOpenReminder)
    assertTrue(DeviceBleProtocolConfig.isValidDoorOpenReminderValue(0L))
    assertTrue(DeviceBleProtocolConfig.isValidDoorOpenReminderValue(5L))
    assertTrue(DeviceBleProtocolConfig.isValidDoorOpenReminderValue(10L))
    assertTrue(DeviceBleProtocolConfig.isValidDoorOpenReminderValue(15L))
    assertFalse(DeviceBleProtocolConfig.isValidDoorOpenReminderValue(6L))

    val packet = DeviceBleProtocolConfig.buildEncryptedCommandFrame(
      sequence = 11,
      command = DeviceBleProtocolConfig.commandDoorOpenReminder,
      aesKeyHex = correctKey,
      data = byteArrayOf(0x0A),
    )
    val encryptedPayload = packet.copyOfRange(5, packet.size - 3)
    val plaintext = DeviceBleProtocolConfig.tryDecryptAesEcbPkcs7(
      encryptedPayload,
      DeviceBleProtocolConfig.candidateAesKeys(correctKey).single().keyBytes,
    )
    val decoded = requireNotNull(
      DeviceBleProtocolConfig.parseDecryptedPayload(
        requireNotNull(plaintext),
        DeviceBleProtocolConfig.cryptoAes128,
      ),
    )

    assertEquals(DeviceBleProtocolConfig.commandDoorOpenReminder, decoded.command)
    assertArrayEquals(byteArrayOf(0x0A), decoded.data)
    assertEquals(0x01, DeviceBleProtocolConfig.doorOpenReminderResponseCode(byteArrayOf(0x01)))
    assertEquals(0x00, DeviceBleProtocolConfig.doorOpenReminderResponseCode(byteArrayOf(0x00)))
    assertEquals(null, DeviceBleProtocolConfig.doorOpenReminderResponseCode(byteArrayOf()))
    assertEquals(null, DeviceBleProtocolConfig.doorOpenReminderResponseCode(byteArrayOf(0x01, 0x00)))
  }

  @Test
  fun `safety accessory pairing separates start acknowledgement from final result`() {
    val startAck = byteArrayOf(0x01, 0x97.toByte(), 0xBC.toByte(), 0x00, 0x00, 0x00, 0x00)
    val parsedAck = DeviceBleProtocolConfig.parseSafetyAccessoryPairingStartAcknowledgement(
      command = DeviceBleProtocolConfig.commandSafetyAccessoryPairing,
      control = DeviceBleProtocolConfig.controlSafetyAccessoryPairingStart,
      data = startAck,
    )
    assertEquals(0x01, parsedAck?.resultCode)
    assertEquals(0x97BC, parsedAck?.pairingFlowId)
    assertEquals(0L, parsedAck?.reasonCode)

    val finalSuccess = DeviceBleProtocolConfig.parseSafetyAccessoryPairingFinalReport(
      frameType = DeviceBleProtocolConfig.frameTypeRequest,
      command = DeviceBleProtocolConfig.commandSafetyAccessoryPairingResult,
      data = byteArrayOf(0x97.toByte(), 0xBC.toByte(), 0x01),
    )
    assertEquals(0x01, finalSuccess?.resultCode)
    assertEquals(0x97BC, finalSuccess?.pairingFlowId)
    assertEquals(0L, finalSuccess?.reasonCode)
    assertTrue(
      DeviceBleProtocolConfig.matchesSafetyAccessoryPairingFinalReport(
        pairingFlowId = 0x97BC,
        report = requireNotNull(finalSuccess),
      ),
    )
    assertFalse(
      DeviceBleProtocolConfig.matchesSafetyAccessoryPairingFinalReport(
        pairingFlowId = 0xE2CA,
        report = finalSuccess,
      ),
    )

    val finalFailure = DeviceBleProtocolConfig.parseSafetyAccessoryPairingFinalReport(
      frameType = DeviceBleProtocolConfig.frameTypeRequest,
      command = DeviceBleProtocolConfig.commandSafetyAccessoryPairingResult,
      data = byteArrayOf(0x97.toByte(), 0xBC.toByte(), 0x02),
    )
    assertEquals(0x02, finalFailure?.resultCode)
    assertEquals(0L, finalFailure?.reasonCode)
    assertEquals(
      0x03,
      DeviceBleProtocolConfig.parseSafetyAccessoryPairingFinalReport(
        frameType = DeviceBleProtocolConfig.frameTypeRequest,
        command = DeviceBleProtocolConfig.commandSafetyAccessoryPairingResult,
        data = byteArrayOf(0x97.toByte(), 0xBC.toByte(), 0x03),
      )?.resultCode,
    )
    assertEquals(
      null,
      DeviceBleProtocolConfig.parseSafetyAccessoryPairingFinalReport(
        frameType = DeviceBleProtocolConfig.frameTypeResponse,
        command = DeviceBleProtocolConfig.commandSafetyAccessoryPairing,
        data = byteArrayOf(0x01, 0x00, 0x00, 0x00, 0x00),
      ),
    )
    assertEquals(
      null,
      DeviceBleProtocolConfig.parseSafetyAccessoryPairingFinalReport(
        frameType = DeviceBleProtocolConfig.frameTypeRequest,
        command = DeviceBleProtocolConfig.commandSafetyAccessoryPairingResult,
        data = byteArrayOf(0x97.toByte(), 0xBC.toByte(), 0x7F),
      ),
    )
  }

  @Test
  fun `request frame type is accepted only for remote pairing result`() {
    assertTrue(
      DeviceBleProtocolConfig.matchesProtocolResponse(
        frameType = DeviceBleProtocolConfig.frameTypeRequest,
        command = DeviceBleProtocolConfig.commandRemotePairingResponse,
        expectedCommand = DeviceBleProtocolConfig.commandRemotePairingResponse,
      ),
    )
    assertFalse(
      DeviceBleProtocolConfig.matchesProtocolResponse(
        frameType = DeviceBleProtocolConfig.frameTypeRequest,
        command = DeviceBleProtocolConfig.commandScanWifi,
        expectedCommand = DeviceBleProtocolConfig.commandScanWifi,
      ),
    )
    assertTrue(
      DeviceBleProtocolConfig.matchesProtocolResponse(
        frameType = DeviceBleProtocolConfig.frameTypeResponse,
        command = DeviceBleProtocolConfig.commandScanWifi,
        expectedCommand = DeviceBleProtocolConfig.commandScanWifi,
      ),
    )
  }
}
