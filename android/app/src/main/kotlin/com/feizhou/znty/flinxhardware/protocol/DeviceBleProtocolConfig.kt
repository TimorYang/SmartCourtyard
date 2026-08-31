package com.feizhou.znty.flinxhardware.protocol

import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.UUID
import javax.crypto.Cipher
import javax.crypto.spec.SecretKeySpec

/**
 * 新硬件 BLE 协议配置：
 * 统一收口 BLE Service/Characteristic、固定 token，以及 APP <-> Device 业务帧编解码约定。
 */
object DeviceBleProtocolConfig {
  const val fixedCommunicationTokenMd5 = "AF035A47A6ABB06B884F28409EFB8E44"

  val communicationServiceUuid: UUID =
    UUID.fromString("02362AF7-CF3A-11E1-EFDC-000215D5C51B")
  val writeCharacteristicUuid: UUID =
    UUID.fromString("02362A10-CF3A-11E1-EFDC-000215D5C51B")
  val notifyCharacteristicUuid: UUID =
    UUID.fromString("02362A11-CF3A-11E1-EFDC-000215D5C51B")
  val logServiceUuid: UUID =
    UUID.fromString("02367AF7-CF3A-11E1-EFDC-000215D5C51B")
  val logNotifyCharacteristicUuid: UUID =
    UUID.fromString("02367A11-CF3A-11E1-EFDC-000215D5C51B")

  const val frameHeader: Int = 0x5555
  const val frameFooter: Int = 0xAAAA

  const val cryptoNone: Int = 0x00
  const val cryptoAes128: Int = 0x01

  const val frameTypeRequest: Int = 0x03
  const val frameTypeResponse: Int = 0x04

  const val commandScanWifi: Int = 0x0E01
  const val commandConfigureWifi: Int = 0x0E02
  const val commandAuthenticate: Int = 0x0E03
  const val commandDoorOpenReminder: Int = 0x0E09
  const val commandQueryAttributes: Int = 0x0002
  const val commandSetAttributes: Int = 0x0001
  const val commandAttributeReport: Int = 0x0202
  const val commandControlDoor: Int = 0x0005
  const val commandRemotePairingResponse: Int = 0x0104
  const val commandRemoteQuery: Int = 0x0008
  const val commandRemoteDelete: Int = 0x0009
  const val commandRemoteRename: Int = 0x000A
  const val commandSafetyAccessoryPairing: Int = 0x000B
  const val commandSafetyAccessoryPairingResult: Int = 0x0012
  const val controlSafetyAccessoryPairingStart: Int = 0x100A
  const val controlSafetyAccessoryPairingCancel: Int = 0x100B
  const val safetyAccessoryPairingSuccessResult: Int = 0x01
  const val safetyAccessoryPairingFailureResult: Int = 0x02
  const val safetyAccessoryPairingTimeoutResult: Int = 0x03
  const val safetyAccessoryPairingStartAcknowledgementDataLength: Int = 7
  const val safetyAccessoryPairingResultDataLength: Int = 3
  const val controlOpenDoor: Int = 0x1001
  const val controlCloseDoor: Int = 0x1002
  const val controlStopDoor: Int = 0x1003
  const val controlPartialOpenDoor: Int = 0x1004
  const val controlLightOn: Int = 0x1005
  const val controlLightOff: Int = 0x1006
  const val controlPb: Int = 0x1007
  const val controlRemotePairingStart: Int = 0x1008
  const val controlRemotePairingCancel: Int = 0x1009
  const val resultRemotePairingSuccess: Int = 0x06
  const val resultRemotePairingFailure: Int = 0x05
  const val remotePairingResponseTimeoutMillis: Long = 20_000L

  fun isValidDoorOpenReminderValue(value: Long): Boolean {
    return value == 0L || value == 5L || value == 10L || value == 15L
  }

  fun doorOpenReminderResponseCode(data: ByteArray): Int? {
    return if (data.size == 1) data[0].toInt() and 0xFF else null
  }

  fun parseSafetyAccessoryPairingStartAcknowledgement(
    command: Int,
    control: Int?,
    data: ByteArray,
  ): SafetyAccessoryPairingAcknowledgement? {
    if (command != commandSafetyAccessoryPairing ||
      control != controlSafetyAccessoryPairingStart ||
      data.size != safetyAccessoryPairingStartAcknowledgementDataLength ||
      (data[0].toInt() and 0xFF) != safetyAccessoryPairingSuccessResult
    ) {
      return null
    }
    val reasonCode = ByteBuffer.wrap(data, 3, 4)
      .order(ByteOrder.BIG_ENDIAN)
      .int
      .toLong() and 0xffffffffL
    if (reasonCode != 0L) {
      return null
    }
    return SafetyAccessoryPairingAcknowledgement(
      resultCode = data[0].toInt() and 0xFF,
      pairingFlowId = ByteBuffer.wrap(data, 1, 2).order(ByteOrder.BIG_ENDIAN).short.toInt() and 0xFFFF,
      reasonCode = reasonCode,
    )
  }

  fun parseSafetyAccessoryPairingFinalReport(
    frameType: Int,
    command: Int,
    data: ByteArray,
  ): SafetyAccessoryPairingResponse? {
    if (frameType != frameTypeRequest ||
      command != commandSafetyAccessoryPairingResult ||
      data.size != safetyAccessoryPairingResultDataLength
    ) {
      return null
    }
    val resultCode = data[2].toInt() and 0xFF
    if (resultCode !in setOf(
        safetyAccessoryPairingSuccessResult,
        safetyAccessoryPairingFailureResult,
        safetyAccessoryPairingTimeoutResult,
      )
    ) {
      return null
    }
    return SafetyAccessoryPairingResponse(
      resultCode = resultCode,
      pairingFlowId = ByteBuffer.wrap(data, 0, 2).order(ByteOrder.BIG_ENDIAN).short.toInt() and 0xFFFF,
      reasonCode = 0L,
    )
  }

  fun matchesSafetyAccessoryPairingFinalReport(
    pairingFlowId: Int?,
    report: SafetyAccessoryPairingResponse,
  ): Boolean = pairingFlowId != null && pairingFlowId == report.pairingFlowId

  const val authTokenHexLength: Int = 32
  const val authTokenBinaryLengthBytes: Int = 16

  fun buildAuthenticationFrame(
    sequence: Int,
    utcTimestampSeconds: Long,
    tokenMd5: String = fixedCommunicationTokenMd5,
    aesKeyHex: String,
    cryptoType: Int = cryptoAes128,
  ): ByteArray {
    require(tokenMd5.length == authTokenHexLength) {
      "Authentication token must be a 32-byte MD5 hex string."
    }
    val tokenBytes = requireNotNull(hexToBytesOrNull(tokenMd5)) {
      "Authentication token must be valid hex."
    }
    require(tokenBytes.size == authTokenBinaryLengthBytes) {
      "Authentication token must decode to 16 bytes."
    }
    val timestampBytes = ByteBuffer.allocate(4)
      .order(ByteOrder.BIG_ENDIAN)
      .putInt(utcTimestampSeconds.toInt())
      .array()
    return buildEncryptedFrame(
      frameType = frameTypeRequest,
      sequence = sequence,
      command = commandAuthenticate,
      data = timestampBytes + tokenBytes,
      aesKeyHex = aesKeyHex,
      cryptoType = cryptoType,
    )
  }

  fun remotePairingResult(result: Int): DeviceRemotePairingResult {
    return when (result) {
      resultRemotePairingSuccess -> DeviceRemotePairingResult.SUCCESS
      resultRemotePairingFailure -> DeviceRemotePairingResult.FAILURE
      else -> DeviceRemotePairingResult.UNKNOWN
    }
  }

  fun matchesProtocolResponse(
    frameType: Int,
    command: Int,
    expectedCommand: Int,
  ): Boolean {
    if (command != expectedCommand) {
      return false
    }
    return frameType == frameTypeResponse ||
      (frameType == frameTypeRequest && command == commandRemotePairingResponse)
  }

  fun buildEncryptedCommandFrame(
    sequence: Int,
    command: Int,
    aesKeyHex: String,
    data: ByteArray = ByteArray(0),
    cryptoType: Int = cryptoAes128,
  ): ByteArray {
    return buildEncryptedFrame(
      frameType = frameTypeRequest,
      sequence = sequence,
      command = command,
      data = data,
      aesKeyHex = aesKeyHex,
      cryptoType = cryptoType,
    )
  }

  fun buildEncryptedFrame(
    frameType: Int,
    sequence: Int,
    command: Int,
    data: ByteArray = ByteArray(0),
    aesKeyHex: String,
    cryptoType: Int = cryptoAes128,
  ): ByteArray {
    val keyBytes = requireAesKeyBytes(aesKeyHex)
    val plainTypeToData = ByteBuffer.allocate(1 + 2 + 2 + data.size)
      .order(ByteOrder.BIG_ENDIAN)
      .put(frameType.toByte())
      .putShort(sequence.toShort())
      .putShort(command.toShort())
      .put(data)
      .array()
    val encryptedTypeToData = encryptAesEcbPkcs7(
      plainBytes = plainTypeToData,
      keyBytes = keyBytes,
    )
    return buildFramedCipherPayload(
      cryptoType = cryptoType,
      cipherPayload = encryptedTypeToData,
    )
  }

  fun buildFrame(
    cryptoType: Int,
    frameType: Int,
    sequence: Int,
    command: Int,
    data: ByteArray = ByteArray(0),
  ): ByteArray {
    val frameLength = 2 + 2 + 1 + 1 + 2 + 2 + data.size + 1 + 2
    val buffer = ByteBuffer.allocate(frameLength).order(ByteOrder.BIG_ENDIAN)
    buffer.putShort(frameHeader.toShort())
    buffer.putShort(frameLength.toShort())
    buffer.put(cryptoType.toByte())
    buffer.put(frameType.toByte())
    buffer.putShort(sequence.toShort())
    buffer.putShort(command.toShort())
    buffer.put(data)

    val bcc = calculateBcc(buffer.array(), buffer.position())
    buffer.put(bcc.toByte())
    buffer.putShort(frameFooter.toShort())
    return buffer.array()
  }

  private fun buildFramedCipherPayload(
    cryptoType: Int,
    cipherPayload: ByteArray,
  ): ByteArray {
    val frameLength = 2 + 2 + 1 + cipherPayload.size + 1 + 2
    val buffer = ByteBuffer.allocate(frameLength).order(ByteOrder.BIG_ENDIAN)
    buffer.putShort(frameHeader.toShort())
    buffer.putShort(frameLength.toShort())
    buffer.put(cryptoType.toByte())
    buffer.put(cipherPayload)
    val bcc = calculateBcc(buffer.array(), buffer.position())
    buffer.put(bcc.toByte())
    buffer.putShort(frameFooter.toShort())
    return buffer.array()
  }

  fun parseFrame(payload: ByteArray): DeviceBleFrame? {
    if (payload.size < 13) return null
    val buffer = ByteBuffer.wrap(payload).order(ByteOrder.BIG_ENDIAN)
    val header = buffer.short.toInt() and 0xFFFF
    if (header != frameHeader) return null
    val length = buffer.short.toInt() and 0xFFFF
    if (length != payload.size) return null
    val cryptoType = buffer.get().toInt() and 0xFF
    val frameType = buffer.get().toInt() and 0xFF
    val sequence = buffer.short.toInt() and 0xFFFF
    val command = buffer.short.toInt() and 0xFFFF
    val dataLength = payload.size - 13
    val data = ByteArray(dataLength)
    buffer.get(data)
    val bcc = buffer.get().toInt() and 0xFF
    val footer = buffer.short.toInt() and 0xFFFF
    if (footer != frameFooter) return null
    val expectedBcc = calculateBcc(payload, payload.size - 3)
    if (bcc != expectedBcc) return null
    return DeviceBleFrame(
      cryptoType = cryptoType,
      frameType = frameType,
      sequence = sequence,
      command = command,
      data = data,
    )
  }

  fun hasValidEnvelope(payload: ByteArray): Boolean {
    if (payload.size < 8) return false
    val header = ((payload[0].toInt() and 0xFF) shl 8) or (payload[1].toInt() and 0xFF)
    if (header != frameHeader) return false
    val length = ((payload[2].toInt() and 0xFF) shl 8) or (payload[3].toInt() and 0xFF)
    if (length != payload.size) return false
    val footer = ((payload[payload.size - 2].toInt() and 0xFF) shl 8) or
      (payload[payload.size - 1].toInt() and 0xFF)
    if (footer != frameFooter) return false
    val bcc = payload[payload.size - 3].toInt() and 0xFF
    val expectedBcc = calculateBcc(payload, payload.size - 3)
    return bcc == expectedBcc
  }

  fun supportsService(serviceUuid: String): Boolean {
    return serviceUuid.equals(communicationServiceUuid.toString(), ignoreCase = true) ||
      serviceUuid.equals(logServiceUuid.toString(), ignoreCase = true)
  }

  fun toHex(bytes: ByteArray): String {
    return bytes.joinToString(separator = "") { "%02X".format(it) }
  }

  fun candidateAesKeys(aesKeyHex: String): List<DeviceBleAesKeyCandidate> {
    return listOf(
      DeviceBleAesKeyCandidate(
        label = "server_key_hex_16",
        keyBytes = requireAesKeyBytes(aesKeyHex),
      ),
    )
  }

  fun tryDecryptAesEcbPkcs7(
    cipherBytes: ByteArray,
    keyBytes: ByteArray,
  ): ByteArray? {
    return decrypt("AES/ECB/PKCS5Padding", cipherBytes, keyBytes)
  }

  fun tryDecryptAesEcbNoPadding(
    cipherBytes: ByteArray,
    keyBytes: ByteArray,
  ): ByteArray? {
    return decrypt("AES/ECB/NoPadding", cipherBytes, keyBytes)
  }

  fun tryDecryptAesCbcPkcs7ZeroIv(
    cipherBytes: ByteArray,
    keyBytes: ByteArray,
  ): ByteArray? {
    return decrypt(
      transformation = "AES/CBC/PKCS5Padding",
      cipherBytes = cipherBytes,
      keyBytes = keyBytes,
      ivBytes = ByteArray(16),
    )
  }

  fun parseDecryptedPayload(
    plaintext: ByteArray,
    cryptoType: Int,
  ): DeviceBleFrame? {
    if (plaintext.size < 5) {
      return null
    }
    val buffer = ByteBuffer.wrap(plaintext).order(ByteOrder.BIG_ENDIAN)
    val frameType = buffer.get().toInt() and 0xFF
    val sequence = buffer.short.toInt() and 0xFFFF
    val command = buffer.short.toInt() and 0xFFFF
    val data = ByteArray(plaintext.size - 5)
    buffer.get(data)
    return DeviceBleFrame(
      cryptoType = cryptoType,
      frameType = frameType,
      sequence = sequence,
      command = command,
      data = data,
    )
  }

  fun decodeExpectedEncryptedResponse(
    payload: ByteArray,
    aesKeyHex: String,
    expectedSequence: Int,
    expectedCommand: Int,
  ): DeviceBleDecodeResult {
    if (!hasValidEnvelope(payload) || (payload[4].toInt() and 0xFF) != cryptoAes128) {
      return DeviceBleDecodeResult(DeviceBleDecodeStatus.INVALID_ENVELOPE)
    }
    val encryptedPayload = payload.copyOfRange(5, payload.size - 3)
    for (candidate in candidateAesKeys(aesKeyHex)) {
      val modes = listOf(
        "AES-128-ECB-PKCS7" to
          tryDecryptAesEcbPkcs7(encryptedPayload, candidate.keyBytes),
        "AES-128-CBC-PKCS7-zero-IV" to
          tryDecryptAesCbcPkcs7ZeroIv(encryptedPayload, candidate.keyBytes),
      )
      for ((mode, plaintext) in modes) {
        val frame = plaintext?.let {
          parseDecryptedPayload(it, cryptoAes128)
        } ?: continue
        if (frame.frameType == frameTypeResponse &&
          frame.sequence == expectedSequence &&
          frame.command == expectedCommand
        ) {
          return DeviceBleDecodeResult(
            status = DeviceBleDecodeStatus.MATCHED,
            frame = frame,
            mode = mode,
            plaintext = plaintext,
          )
        }
      }
    }
    return DeviceBleDecodeResult(DeviceBleDecodeStatus.DECRYPT_FAILED)
  }

  private fun calculateBcc(bytes: ByteArray, endExclusive: Int): Int {
    var sum = 0
    for (index in 0 until endExclusive) {
      sum = (sum + (bytes[index].toInt() and 0xFF)) and 0xFF
    }
    return sum
  }

  private fun decrypt(
    transformation: String,
    cipherBytes: ByteArray,
    keyBytes: ByteArray,
    ivBytes: ByteArray? = null,
  ): ByteArray? {
    return runCatching {
      val cipher = Cipher.getInstance(transformation)
      if (ivBytes != null) {
        cipher.init(
          Cipher.DECRYPT_MODE,
          SecretKeySpec(keyBytes, "AES"),
          javax.crypto.spec.IvParameterSpec(ivBytes),
        )
      } else {
        cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(keyBytes, "AES"))
      }
      cipher.doFinal(cipherBytes)
    }.getOrNull()
  }

  private fun encryptAesEcbPkcs7(
    plainBytes: ByteArray,
    keyBytes: ByteArray,
  ): ByteArray {
    val cipher = Cipher.getInstance("AES/ECB/PKCS5Padding")
    cipher.init(Cipher.ENCRYPT_MODE, SecretKeySpec(keyBytes, "AES"))
    return cipher.doFinal(plainBytes)
  }

  private fun hexToBytesOrNull(hex: String): ByteArray? {
    if (hex.length % 2 != 0) return null
    return runCatching {
      ByteArray(hex.length / 2) { index ->
        hex.substring(index * 2, index * 2 + 2).toInt(16).toByte()
      }
    }.getOrNull()
  }

  fun isValidAesKeyHex(aesKeyHex: String): Boolean {
    val normalized = aesKeyHex.trim()
    return normalized.length == 32 && hexToBytesOrNull(normalized)?.size == 16
  }

  private fun requireAesKeyBytes(aesKeyHex: String): ByteArray {
    val normalized = aesKeyHex.trim()
    val bytes = hexToBytesOrNull(normalized)
    require(normalized.length == 32 && bytes?.size == 16) {
      "AES key must be a 32-character hexadecimal string."
    }
    return requireNotNull(bytes)
  }

}

data class DeviceBleFrame(
  val cryptoType: Int,
  val frameType: Int,
  val sequence: Int,
  val command: Int,
  val data: ByteArray,
)

data class SafetyAccessoryPairingResponse(
  val resultCode: Int,
  val pairingFlowId: Int,
  val reasonCode: Long,
)

data class SafetyAccessoryPairingAcknowledgement(
  val resultCode: Int,
  val pairingFlowId: Int,
  val reasonCode: Long,
)

data class DeviceBleAesKeyCandidate(
  val label: String,
  val keyBytes: ByteArray,
)

enum class DeviceBleDecodeStatus { MATCHED, DECRYPT_FAILED, INVALID_ENVELOPE }

enum class DeviceRemotePairingResult { SUCCESS, FAILURE, UNKNOWN }

data class DeviceBleDecodeResult(
  val status: DeviceBleDecodeStatus,
  val frame: DeviceBleFrame? = null,
  val mode: String? = null,
  val plaintext: ByteArray? = null,
)
