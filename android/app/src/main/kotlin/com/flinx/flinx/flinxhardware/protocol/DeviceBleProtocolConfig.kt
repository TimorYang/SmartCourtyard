package com.flinx.flinx.flinxhardware.protocol

import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.charset.StandardCharsets
import java.util.UUID
import javax.crypto.Cipher
import javax.crypto.spec.SecretKeySpec

/**
 * 新硬件 BLE 协议配置：
 * 统一收口 BLE Service/Characteristic、固定 token，以及 APP <-> Device 业务帧编解码约定。
 */
object DeviceBleProtocolConfig {
  const val fixedCommunicationTokenMd5 = "AF035A47A6ABB06B884F28409EFB8E44"
  const val fixedAesKeyHex = "1BEE89494F466512FF584DDF85B39AA6"

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

  const val commandAuthenticate: Int = 0x0E03
  const val commandQueryAttributes: Int = 0x0002
  const val commandControlDoor: Int = 0x0005

  const val authTokenHexLength: Int = 32
  const val authTokenBinaryLengthBytes: Int = 16
  const val authPayloadLengthBytes: Int = 20

  fun buildAuthenticationFrame(
    sequence: Int,
    utcTimestampSeconds: Long,
    tokenMd5: String = fixedCommunicationTokenMd5,
    cryptoType: Int = cryptoAes128,
  ): ByteArray {
    require(tokenMd5.length == authTokenHexLength) {
      "Authentication token must be a 32-byte MD5 hex string."
    }
    val keyBytes = requireNotNull(hexToBytesOrNull(fixedAesKeyHex)) {
      "Authentication key must be a valid 16-byte hex string."
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
    val plainTypeToData = ByteBuffer.allocate(1 + 2 + 2 + authPayloadLengthBytes)
      .order(ByteOrder.BIG_ENDIAN)
      .put(frameTypeRequest.toByte())
      .putShort(sequence.toShort())
      .putShort(commandAuthenticate.toShort())
      .put(timestampBytes)
      .put(tokenBytes)
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

  fun candidateAesKeys(): List<DeviceBleAesKeyCandidate> {
    val tokenHexBytes = hexToBytesOrNull(fixedAesKeyHex)
    val tokenAsciiBytes = fixedAesKeyHex.toByteArray(StandardCharsets.UTF_8)
    val candidates = mutableListOf<DeviceBleAesKeyCandidate>()
    if (tokenHexBytes != null && tokenHexBytes.size == 16) {
      candidates += DeviceBleAesKeyCandidate(
        label = "token_hex_16",
        keyBytes = tokenHexBytes,
      )
    }
    if (tokenAsciiBytes.size >= 16) {
      candidates += DeviceBleAesKeyCandidate(
        label = "token_ascii_first16",
        keyBytes = tokenAsciiBytes.copyOf(16),
      )
      candidates += DeviceBleAesKeyCandidate(
        label = "token_ascii_last16",
        keyBytes = tokenAsciiBytes.copyOfRange(tokenAsciiBytes.size - 16, tokenAsciiBytes.size),
      )
    }
    return candidates
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

}

data class DeviceBleFrame(
  val cryptoType: Int,
  val frameType: Int,
  val sequence: Int,
  val command: Int,
  val data: ByteArray,
)

data class DeviceBleAesKeyCandidate(
  val label: String,
  val keyBytes: ByteArray,
)
