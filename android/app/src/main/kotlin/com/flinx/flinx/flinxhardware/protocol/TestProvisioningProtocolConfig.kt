package com.flinx.flinx.flinxhardware.protocol

import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.UUID
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * 测试配网协议配置：
 * 统一收口 BLE 广播/GATT UUID、固定加密参数以及临时测试协议的加解密逻辑。
 *
 * 这份实现基于《蓝牙辅助配网流程 V1.4.pdf》，仅用于当前联调测试；
 * 后续替换真实设备协议时，优先替换本类而不是把协议常量和算法散落到 BLE 业务代码中。
 */
object TestProvisioningProtocolConfig {
  const val controllerBleName = "HEMS_Controller"
  const val chargerBleName = "EV_Charger"
  const val manufacturerDataPrefix = "EE"

  val communicationServiceUuid: UUID = uuidFromShort("FEB3")
  val readCharacteristicUuid: UUID = uuidFromShort("FED4")
  val keyExchangeCharacteristicUuid: UUID = uuidFromShort("FED5")
  /** 当前测试协议实际使用的鉴权管道：写入和读取都走 FED5。 */
  val authenticationCharacteristicUuid: UUID = keyExchangeCharacteristicUuid
  /** 旧的 notify 管道预留位，当前测试鉴权流程不使用。 */
  val notifyCharacteristicUuid: UUID = uuidFromShort("FED6")
  val wifiProvisionCharacteristicUuid: UUID = uuidFromShort("FED7")
  val statusReadCharacteristicUuid: UUID = uuidFromShort("FED8")

  private const val aesTransformation = "AES/CBC/PKCS5Padding"
  private val fixedIvBytes = "enjoyelec@123456".toByteArray(StandardCharsets.UTF_8)

  /** 构建临时测试协议使用的 IKM：`key_data,product_name,serial_name`。 */
  fun buildIkm(
    keyData: ByteArray,
    productName: String,
    serialName: ByteArray,
  ): ByteArray {
    return keyData +
      byteArrayOf(COMMA_BYTE) +
      productName.toByteArray(StandardCharsets.UTF_8) +
      byteArrayOf(COMMA_BYTE) +
      serialName
  }

  /** 生成一段测试用 `key_data`，长度固定为 16 字节。 */
  fun generateKeyData(): ByteArray {
    return ByteArray(AES_KEY_SIZE_BYTES).also { SecureRandom().nextBytes(it) }
  }

  /** 根据协议约定：`SHA-256(ikm)` 后取前 16 字节，得到 AES-128 会话密钥。 */
  fun deriveSessionKey(
    keyData: ByteArray,
    productName: String,
    serialName: ByteArray,
  ): ByteArray {
    val ikm = buildIkm(
      keyData = keyData,
      productName = productName,
      serialName = serialName,
    )
    val digest = MessageDigest.getInstance("SHA-256").digest(ikm)
    return digest.copyOf(AES_KEY_SIZE_BYTES)
  }

  /** 组装发给设备的 key_data 协议包：`00 10 00 10 + 16字节key_data`。 */
  fun buildKeyExchangePacket(keyData: ByteArray): ByteArray {
    require(keyData.size == AES_KEY_SIZE_BYTES) {
      "Key data must be 16 bytes."
    }
    return byteArrayOf(0x00, 0x10, 0x00, 0x10) + keyData
  }

  /** 使用协议固定参数执行 AES-CBC 加密。 */
  fun encrypt(
    plainBytes: ByteArray,
    sessionKey: ByteArray,
  ): ByteArray {
    require(sessionKey.size == AES_KEY_SIZE_BYTES) {
      "Session key must be 16 bytes for AES-128."
    }
    val cipher = Cipher.getInstance(aesTransformation)
    cipher.init(
      Cipher.ENCRYPT_MODE,
      SecretKeySpec(sessionKey, "AES"),
      IvParameterSpec(fixedIvBytes),
    )
    return cipher.doFinal(plainBytes)
  }

  /** 使用协议固定参数执行 AES-CBC 解密。 */
  fun decrypt(
    cipherBytes: ByteArray,
    sessionKey: ByteArray,
  ): ByteArray {
    require(sessionKey.size == AES_KEY_SIZE_BYTES) {
      "Session key must be 16 bytes for AES-128."
    }
    val cipher = Cipher.getInstance(aesTransformation)
    cipher.init(
      Cipher.DECRYPT_MODE,
      SecretKeySpec(sessionKey, "AES"),
      IvParameterSpec(fixedIvBytes),
    )
    return cipher.doFinal(cipherBytes)
  }

  /** 判断扫描到的设备名是否属于当前测试协议设备。 */
  fun isSupportedBleName(name: String?): Boolean {
    return name == controllerBleName || name == chargerBleName
  }

  /** 从广播原始 manufacturer data 中提取 SN 字节，默认取第一个逗号后的内容。 */
  fun extractSerialBytes(manufacturerData: ByteArray): ByteArray {
    val commaIndex = manufacturerData.indexOf(COMMA_BYTE)
    return if (commaIndex >= 0 && commaIndex + 1 < manufacturerData.size) {
      manufacturerData.copyOfRange(commaIndex + 1, manufacturerData.size)
    } else {
      ByteArray(0)
    }
  }

  /** 将字节数组转成十六进制文本，便于日志打印。 */
  fun toHex(bytes: ByteArray): String {
    return bytes.joinToString(separator = "") { byte ->
      "%02X".format(byte)
    }
  }

  /** 协议里的短 UUID 统一扩展为 128-bit BLE UUID。 */
  private fun uuidFromShort(shortUuid: String): UUID {
    return UUID.fromString("0000$shortUuid-0000-1000-8000-00805F9B34FB")
  }

  private const val COMMA_BYTE: Byte = 0x2c
  private const val AES_KEY_SIZE_BYTES = 16
}
