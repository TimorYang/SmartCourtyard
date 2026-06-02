package com.flinx.flinx.flinxhardware.bluetooth

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import com.flinx.flinx.flinxhardware.bridge.BleDeviceDto
import com.flinx.flinx.flinxhardware.bridge.BleConnectionEventDto
import com.flinx.flinx.flinxhardware.bridge.BleConnectionStateDto
import com.flinx.flinx.flinxhardware.bridge.BleCharacteristicDto
import com.flinx.flinx.flinxhardware.bridge.BleScanFilterDto
import com.flinx.flinx.flinxhardware.bridge.BleServiceDto
import com.flinx.flinx.flinxhardware.bridge.BleServicesDto
import com.flinx.flinx.flinxhardware.bridge.FlutterError
import com.flinx.flinx.flinxhardware.protocol.TestProvisioningProtocolConfig
import java.util.concurrent.ConcurrentHashMap

/** BLE 管理器：负责扫描生命周期和扫描结果到 DTO 的转换。 */
class BleManager(
  private val context: Context,
) {
  companion object {
    private const val TAG = "BleManager"
    private const val NO_RESULT_LOG_DELAY_MS = 5_000L
  }

  private val mainHandler = Handler(Looper.getMainLooper())
  private var scanner: BluetoothLeScanner? = null
  private var activeScanCallback: ScanCallback? = null
  private var activeRequestId: String? = null
  private var hasScanResult = false
  private var onDeviceFound: ((BleDeviceDto) -> Unit)? = null
  private var onError: ((FlutterError) -> Unit)? = null
  private var noResultLogRunnable: Runnable? = null
  private val gattMap = ConcurrentHashMap<String, BluetoothGatt>()
  private val connectCallbacks = ConcurrentHashMap<String, (Result<BleConnectionEventDto>) -> Unit>()
  private val disconnectCallbacks = ConcurrentHashMap<String, (Result<BleConnectionEventDto>) -> Unit>()
  private val discoverServicesCallbacks = ConcurrentHashMap<String, (Result<BleServicesDto>) -> Unit>()
  private val authSessions = ConcurrentHashMap<String, TestProvisioningAuthSession>()
  private val requestIdsByDevice = ConcurrentHashMap<String, String>()
  private val scanDeviceCache = ConcurrentHashMap<String, BleDeviceDto>()

  /** 启动 BLE 扫描并通过回调输出扫描结果。 */
  @SuppressLint("MissingPermission")
  fun startScan(
    requestId: String,
    filter: BleScanFilterDto,
    onDeviceFound: (BleDeviceDto) -> Unit,
    onError: (FlutterError) -> Unit,
  ) {
    Log.d(
      TAG,
      "startScan requestId=$requestId manufacturer=${Build.MANUFACTURER} model=${Build.MODEL} sdk=${Build.VERSION.SDK_INT} serviceUuids=${filter.serviceUuids} namePrefix=${filter.namePrefix} exactName=${filter.exactName} allowDuplicates=${filter.allowDuplicates}",
    )
    stopScan(requestId)
    val bluetoothAdapter = context.bluetoothAdapterOrNull()
      ?: throw FlutterError("bluetooth_unavailable", "Bluetooth adapter is unavailable.")
    if (!bluetoothAdapter.isEnabled) {
      throw FlutterError("bluetooth_disabled", "Bluetooth is disabled.")
    }
    val bleScanner = bluetoothAdapter.bluetoothLeScanner
      ?: throw FlutterError("ble_scanner_unavailable", "BLE scanner is unavailable.")
    val callback = createScanCallback(requestId)
    val filters = buildScanFilters(filter)
    val settings = ScanSettings.Builder()
      .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
      .build()
    this.scanner = bleScanner
    this.activeScanCallback = callback
    this.activeRequestId = requestId
    this.hasScanResult = false
    this.onDeviceFound = onDeviceFound
    this.onError = onError
    Log.d(TAG, "startScan invoking scanner requestId=$requestId filterCount=${filters.size}")
    bleScanner.startScan(filters, settings, callback)
    Log.d(TAG, "startScan invoked scanner requestId=$requestId")
    scheduleNoResultLog(requestId)
  }

  /** 停止当前 BLE 扫描。 */
  @SuppressLint("MissingPermission")
  fun stopScan(requestId: String) {
    cancelNoResultLog()
    val currentRequestId = activeRequestId
    val callback = activeScanCallback
    val currentScanner = scanner
    if (callback == null || currentScanner == null) {
      Log.d(TAG, "stopScan ignored requestId=$requestId activeRequestId=$currentRequestId active=false")
      activeScanCallback = null
      scanner = null
      activeRequestId = null
      hasScanResult = false
      onDeviceFound = null
      onError = null
      return
    }
    Log.d(TAG, "stopScan requestId=$requestId activeRequestId=$currentRequestId")
    currentScanner.stopScan(callback)
    Log.d(TAG, "stopScan completed requestId=$requestId activeRequestId=$currentRequestId")
    activeScanCallback = null
    scanner = null
    activeRequestId = null
    hasScanResult = false
    onDeviceFound = null
    onError = null
  }

  /** 发起 BLE 设备连接，并在连接状态变化时回调结果。 */
  @SuppressLint("MissingPermission")
  fun connectDevice(
    requestId: String,
    deviceId: String,
    onConnectionChanged: (BleConnectionEventDto) -> Unit,
    callback: (Result<BleConnectionEventDto>) -> Unit,
  ) {
    val bluetoothAdapter = context.bluetoothAdapterOrNull()
      ?: throw FlutterError("bluetooth_unavailable", "Bluetooth adapter is unavailable.")
    if (!bluetoothAdapter.isEnabled) {
      throw FlutterError("bluetooth_disabled", "Bluetooth is disabled.")
    }
    val device = runCatching { bluetoothAdapter.getRemoteDevice(deviceId) }.getOrNull()
      ?: throw FlutterError("peripheral_unavailable", "BLE device not found.")
    gattMap.remove(deviceId)?.close()
    requestIdsByDevice[deviceId] = requestId
    connectCallbacks[deviceId] = callback
    val connectingEvent = BleConnectionEventDto(
      requestId = requestId,
      deviceId = deviceId,
      state = BleConnectionStateDto.CONNECTING,
    )
    onConnectionChanged(connectingEvent)
    Log.d(TAG, "connectDevice requestId=$requestId deviceId=$deviceId")
    val gatt = device.connectGatt(
      context,
      false,
      createGattCallback(device, onConnectionChanged),
      BluetoothDevice.TRANSPORT_LE,
    )
    gattMap[deviceId] = gatt
  }

  /** 断开 BLE 设备连接，并在断开完成时回调结果。 */
  @SuppressLint("MissingPermission")
  fun disconnectDevice(
    requestId: String,
    deviceId: String,
    onConnectionChanged: (BleConnectionEventDto) -> Unit,
    callback: (Result<BleConnectionEventDto>) -> Unit,
  ) {
    val gatt = gattMap[deviceId]
      ?: run {
        callback(
          Result.success(
            BleConnectionEventDto(
              requestId = requestId,
              deviceId = deviceId,
              state = BleConnectionStateDto.DISCONNECTED,
            ),
          ),
        )
        return
      }
    requestIdsByDevice[deviceId] = requestId
    disconnectCallbacks[deviceId] = callback
    Log.d(TAG, "disconnectDevice requestId=$requestId deviceId=$deviceId")
    gatt.disconnect()
    val disconnectedEvent = BleConnectionEventDto(
      requestId = requestId,
      deviceId = deviceId,
      state = BleConnectionStateDto.DISCONNECTED,
    )
    onConnectionChanged(disconnectedEvent)
  }

  /** 发起 GATT 服务发现，并将结果转换为桥接 DTO。 */
  @SuppressLint("MissingPermission")
  fun discoverServices(
    requestId: String,
    deviceId: String,
    callback: (Result<BleServicesDto>) -> Unit,
  ) {
    val gatt = gattMap[deviceId]
      ?: throw FlutterError("bluetooth_disconnected", "BLE device is not connected.")
    requestIdsByDevice[deviceId] = requestId
    discoverServicesCallbacks[deviceId] = callback
    Log.d(TAG, "discoverServices requestId=$requestId deviceId=$deviceId")
    val started = gatt.discoverServices()
    if (!started) {
      discoverServicesCallbacks.remove(deviceId)
      throw FlutterError("service_discovery_failed", "Failed to start GATT service discovery.")
    }
  }

  /** 创建 Android 扫描回调，并转换为桥接 DTO。 */
  private fun createScanCallback(requestId: String): ScanCallback {
    return object : ScanCallback() {
      override fun onScanResult(callbackType: Int, result: ScanResult) {
        emitScanResult(requestId, result)
      }

      override fun onBatchScanResults(results: MutableList<ScanResult>) {
        Log.d(TAG, "batch scan results requestId=$requestId count=${results.size}")
        results.forEach { emitScanResult(requestId, it) }
      }

      override fun onScanFailed(errorCode: Int) {
        Log.e(TAG, "scan failed requestId=$requestId errorCode=$errorCode")
        onError?.invoke(
          FlutterError(
            code = "ble_scan_failed",
            message = "BLE scan failed.",
            details = "requestId=$requestId,errorCode=$errorCode",
          ),
        )
      }
    }
  }

  /** 将单条原生扫描结果转换为 DTO 并回推给 Flutter。 */
  private fun emitScanResult(requestId: String, result: ScanResult) {
    val deviceName = result.device?.name ?: result.scanRecord?.deviceName
    if (deviceName.isNullOrBlank() || deviceName.equals("unnamed", ignoreCase = true)) {
      Log.d(
        TAG,
        "scan result ignored requestId=$requestId address=${result.device?.address ?: ""} name=$deviceName",
      )
      return
    }
    hasScanResult = true
    val device = BleDeviceDto(
      requestId = requestId,
      scanSessionId = requestId,
      id = result.device?.address ?: "",
      name = deviceName,
      rssi = result.rssi.toLong(),
      advertisementServiceUuids = result.scanRecord?.serviceUuids?.map { it.uuid.toString() } ?: emptyList(),
      manufacturerData = flattenManufacturerData(result),
      seenAtMillis = System.currentTimeMillis(),
    )
    Log.d(
      TAG,
      "scan result requestId=$requestId address=${device.id} name=${device.name} rssi=${device.rssi} uuids=${device.advertisementServiceUuids}",
    )
    scanDeviceCache[device.id] = device
    onDeviceFound?.invoke(device)
  }

  /** 创建 GATT 连接回调，并将原生状态变化映射为桥接事件。 */
  private fun createGattCallback(
    device: BluetoothDevice,
    onConnectionChanged: (BleConnectionEventDto) -> Unit,
  ): BluetoothGattCallback {
    return object : BluetoothGattCallback() {
      @SuppressLint("MissingPermission")
      override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
        val deviceId = device.address
        val requestId = requestIdsByDevice[deviceId] ?: "unknown"
        Log.d(
          TAG,
          "onConnectionStateChange requestId=$requestId deviceId=$deviceId status=$status newState=$newState",
        )
        when (newState) {
          BluetoothProfile.STATE_CONNECTED -> {
            val event = BleConnectionEventDto(
              requestId = requestId,
              deviceId = deviceId,
              state = BleConnectionStateDto.CONNECTED,
              nativeCode = status.toString(),
            )
            gattMap[deviceId] = gatt
            onConnectionChanged(event)
            connectCallbacks.remove(deviceId)?.invoke(Result.success(event))
            prepareTestProvisioningAuth(requestId, deviceId, gatt)
            val discoverStarted = gatt.discoverServices()
            if (!discoverStarted) {
              Log.w(TAG, "auto discoverServices failed requestId=$requestId deviceId=$deviceId")
              authSessions.remove(deviceId)?.fail("auto discoverServices failed")
            } else {
              Log.d(TAG, "auto discoverServices started requestId=$requestId deviceId=$deviceId")
            }
          }
          BluetoothProfile.STATE_DISCONNECTED -> {
            gatt.close()
            gattMap.remove(deviceId)
            discoverServicesCallbacks.remove(deviceId)
            authSessions.remove(deviceId)?.close()
            val event = BleConnectionEventDto(
              requestId = requestId,
              deviceId = deviceId,
              state = BleConnectionStateDto.DISCONNECTED,
              nativeCode = status.toString(),
            )
            onConnectionChanged(event)
            val disconnectCallback = disconnectCallbacks.remove(deviceId)
            if (disconnectCallback != null) {
              disconnectCallback(Result.success(event))
            } else {
              connectCallbacks.remove(deviceId)?.invoke(Result.success(event))
            }
          }
        }
      }

      /** 设备服务发现完成后，先给外部调用方返回结果，再继续协议鉴权。 */
      override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
        val deviceId = device.address
        val requestId = requestIdsByDevice[deviceId] ?: "unknown"
        Log.d(
          TAG,
          "onServicesDiscovered requestId=$requestId deviceId=$deviceId status=$status serviceCount=${gatt.services.size}",
        )
        logDiscoveredServices(requestId, deviceId, gatt)
        val callback = discoverServicesCallbacks.remove(deviceId)
        if (status != BluetoothGatt.GATT_SUCCESS) {
          callback?.invoke(
            Result.failure(
              FlutterError(
                "service_discovery_failed",
                "GATT service discovery failed.",
                "status=$status,deviceId=$deviceId",
              ),
            ),
          )
          authSessions[deviceId]?.fail("service discovery failed status=$status")
          return
        }
        callback?.invoke(Result.success(mapServices(requestId, deviceId, gatt)))
        authSessions[deviceId]?.beginIfReady()
      }

      /** 接收设备通过 notify 主动推送的特征值变化。 */
      @SuppressLint("MissingPermission")
      override fun onCharacteristicChanged(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
      ) {
        val deviceId = device.address
        val requestId = requestIdsByDevice[deviceId] ?: "unknown"
        Log.d(
          TAG,
          "onCharacteristicChanged requestId=$requestId deviceId=$deviceId service=${characteristic.service.uuid} characteristic=${characteristic.uuid}",
        )
      }

      /** 接收设备通过 read 返回的特征值。 */
      @SuppressLint("MissingPermission")
      override fun onCharacteristicRead(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        status: Int,
      ) {
        val deviceId = device.address
        val requestId = requestIdsByDevice[deviceId] ?: "unknown"
        Log.d(
          TAG,
          "onCharacteristicRead requestId=$requestId deviceId=$deviceId service=${characteristic.service.uuid} characteristic=${characteristic.uuid} status=$status",
        )
        authSessions[deviceId]?.handleCharacteristicRead(characteristic, status)
      }

      /** 记录鉴权过程中关键写操作的完成状态。 */
      @SuppressLint("MissingPermission")
      override fun onCharacteristicWrite(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        status: Int,
      ) {
        val deviceId = device.address
        val requestId = requestIdsByDevice[deviceId] ?: "unknown"
        Log.d(
          TAG,
          "onCharacteristicWrite requestId=$requestId deviceId=$deviceId service=${characteristic.service.uuid} characteristic=${characteristic.uuid} status=$status",
        )
        authSessions[deviceId]?.handleCharacteristicWrite(characteristic, status)
      }

    }
  }

  /** 打印本次连接发现到的全部 Service / Characteristic，便于对照协议 UUID。 */
  private fun logDiscoveredServices(
    requestId: String,
    deviceId: String,
    gatt: BluetoothGatt,
  ) {
    gatt.services.forEach { service ->
      Log.d(
        TAG,
        "discovered service requestId=$requestId deviceId=$deviceId service=${service.uuid} characteristicCount=${service.characteristics.size}",
      )
      service.characteristics.forEach { characteristic ->
        Log.d(
          TAG,
          "discovered characteristic requestId=$requestId deviceId=$deviceId service=${service.uuid} characteristic=${characteristic.uuid} properties=${characteristic.properties}",
        )
      }
    }
  }

  /** 连接成功后自动启动测试协议鉴权。 */
  @SuppressLint("MissingPermission")
  private fun prepareTestProvisioningAuth(
    requestId: String,
    deviceId: String,
    gatt: BluetoothGatt,
  ) {
    val scanDevice = scanDeviceCache[deviceId]
    val productName = scanDevice?.name ?: gatt.device.name ?: ""
    val serialBytes = TestProvisioningProtocolConfig.extractSerialBytes(
      scanDevice?.manufacturerData ?: ByteArray(0),
    )
    val keyData = TestProvisioningProtocolConfig.generateKeyData()
    val sessionKey = TestProvisioningProtocolConfig.deriveSessionKey(
      keyData = keyData,
      productName = productName,
      serialName = serialBytes,
    )
    val session = TestProvisioningAuthSession(
      requestId = requestId,
      deviceId = deviceId,
      gatt = gatt,
      productName = productName,
      serialBytes = serialBytes,
      keyData = keyData,
      sessionKey = sessionKey,
      onDiagnostic = { message -> Log.d(TAG, message) },
      onResult = { success, message ->
        Log.d(
          TAG,
          "protocol auth result requestId=$requestId deviceId=$deviceId success=$success message=$message",
        )
      },
    )
    authSessions[deviceId] = session
  }

  /** 临时测试协议鉴权会话：发送 key_data 并校验设备返回的加密验证包。 */
  private inner class TestProvisioningAuthSession(
    private val requestId: String,
    private val deviceId: String,
    private val gatt: BluetoothGatt,
    private val productName: String,
    private val serialBytes: ByteArray,
    private val keyData: ByteArray,
    private val sessionKey: ByteArray,
    private val onDiagnostic: (String) -> Unit,
    private val onResult: (Boolean, String) -> Unit,
  ) {
    private var finished = false
    private var started = false

    /** 在服务发现完成后真正启动鉴权流程：先写 key_data，再读回验证包。 */
    fun beginIfReady() {
      if (started || finished) return
      started = true
      onDiagnostic(
        "protocol auth start requestId=$requestId deviceId=$deviceId productName=$productName serial=${TestProvisioningProtocolConfig.toHex(serialBytes)} keyData=${TestProvisioningProtocolConfig.toHex(keyData)}",
      )
      if (!writeKeyExchange()) {
        finish(false, "write key exchange failed")
      }
    }

    /** 直接结束当前鉴权会话并记录失败原因。 */
    fun fail(message: String) {
      finish(false, message)
    }

    /** 记录 key_data 写入结果。 */
    fun handleCharacteristicWrite(characteristic: BluetoothGattCharacteristic, status: Int) {
      if (finished) return
      if (characteristic.uuid != TestProvisioningProtocolConfig.authenticationCharacteristicUuid) return
      onDiagnostic(
        "protocol auth key write status=$status requestId=$requestId deviceId=$deviceId",
      )
      if (status != BluetoothGatt.GATT_SUCCESS) {
        finish(false, "key exchange write failed status=$status")
        return
      }
      if (!readVerificationValue()) {
        finish(false, "read verification value failed")
      }
    }

    /** 记录协议管道 read 返回的特征值，并进行解密校验。 */
    fun handleCharacteristicRead(characteristic: BluetoothGattCharacteristic, status: Int) {
      if (finished) return
      if (characteristic.uuid != TestProvisioningProtocolConfig.authenticationCharacteristicUuid) return
      if (status != BluetoothGatt.GATT_SUCCESS) {
        finish(false, "key validation read failed status=$status")
        return
      }
      val value = characteristic.value ?: ByteArray(0)
      onDiagnostic(
        "protocol auth read raw=${TestProvisioningProtocolConfig.toHex(value)} requestId=$requestId deviceId=$deviceId",
      )
      val decrypted = runCatching {
        TestProvisioningProtocolConfig.decrypt(value.dropHeaderIfPresent(), sessionKey)
      }.getOrNull() ?: runCatching {
        TestProvisioningProtocolConfig.decrypt(value, sessionKey)
      }.getOrNull()
      if (decrypted == null) {
        finish(false, "decrypt failed")
        return
      }
      val matches = decrypted.contentEquals(keyData)
      onDiagnostic(
        "protocol auth decrypted=${TestProvisioningProtocolConfig.toHex(decrypted)} expected=${TestProvisioningProtocolConfig.toHex(keyData)} match=$matches requestId=$requestId deviceId=$deviceId",
      )
      finish(matches, if (matches) "key validation success" else "key validation mismatch")
    }

    /** 结束当前鉴权会话，避免重复处理后续回包。 */
    fun close() {
      finished = true
    }

    /** 向协议管道发起 read，请求设备返回加密验证数据。 */
    private fun readVerificationValue(): Boolean {
      val characteristic = resolveAuthenticationCharacteristic() ?: return false
      val started = gatt.readCharacteristic(characteristic)
      onDiagnostic(
        "protocol auth readCharacteristic requestId=$requestId deviceId=$deviceId characteristic=${characteristic.uuid} started=$started",
      )
      return started
    }

    /** 定位测试协议使用的鉴权管道。 */
    private fun resolveAuthenticationCharacteristic(): BluetoothGattCharacteristic? {
      val service = gatt.getService(TestProvisioningProtocolConfig.communicationServiceUuid)
        ?: run {
          onDiagnostic(
            "protocol auth service missing requestId=$requestId deviceId=$deviceId service=${TestProvisioningProtocolConfig.communicationServiceUuid}",
          )
          return null
        }
      val characteristic = service.getCharacteristic(TestProvisioningProtocolConfig.authenticationCharacteristicUuid)
        ?: run {
          onDiagnostic(
            "protocol auth characteristic missing requestId=$requestId deviceId=$deviceId service=${service.uuid} characteristic=${TestProvisioningProtocolConfig.authenticationCharacteristicUuid}",
          )
          return null
        }
      onDiagnostic(
        "protocol auth pipe resolved requestId=$requestId deviceId=$deviceId service=${service.uuid} characteristic=${characteristic.uuid} properties=${characteristic.properties}",
      )
      return characteristic
    }

    /** 向设备写入协议 key_data。 */
    private fun writeKeyExchange(): Boolean {
      val characteristic = resolveAuthenticationCharacteristic() ?: return false
      characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
      characteristic.value = TestProvisioningProtocolConfig.buildKeyExchangePacket(keyData)
      val started = gatt.writeCharacteristic(characteristic)
      onDiagnostic(
        "protocol auth writeCharacteristic requestId=$requestId deviceId=$deviceId characteristic=${characteristic.uuid} started=$started",
      )
      return started
    }

    /** 记录最终鉴权结果。 */
    private fun finish(success: Boolean, message: String) {
      if (finished) return
      finished = true
      onResult(success, message)
      Log.d(
        TAG,
        "protocol auth finish requestId=$requestId deviceId=$deviceId success=$success message=$message",
      )
    }
  }

  /** 去掉协议回包里可能存在的 4 字节头部。 */
  private fun ByteArray.dropHeaderIfPresent(): ByteArray {
    return if (size > 4) copyOfRange(4, size) else this
  }

  /** 将 Android GATT services 映射为跨端 DTO。 */
  private fun mapServices(
    requestId: String,
    deviceId: String,
    gatt: BluetoothGatt,
  ): BleServicesDto {
    return BleServicesDto(
      requestId = requestId,
      deviceId = deviceId,
      services = gatt.services.map { service ->
        BleServiceDto(
          serviceUuid = service.uuid.toString(),
          characteristics = service.characteristics.map(::mapCharacteristic),
        )
      },
    )
  }

  /** 将单个 Android GATT 特征映射为 DTO。 */
  private fun mapCharacteristic(characteristic: BluetoothGattCharacteristic): BleCharacteristicDto {
    val properties = characteristic.properties
    return BleCharacteristicDto(
      serviceUuid = characteristic.service.uuid.toString(),
      characteristicUuid = characteristic.uuid.toString(),
      canRead = properties and BluetoothGattCharacteristic.PROPERTY_READ != 0,
      canWriteWithResponse = properties and BluetoothGattCharacteristic.PROPERTY_WRITE != 0,
      canWriteWithoutResponse = properties and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE != 0,
      canNotify = properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0,
    )
  }

  /** 在扫描开始后一段时间内无结果时打印诊断日志。 */
  private fun scheduleNoResultLog(requestId: String) {
    cancelNoResultLog()
    val runnable = Runnable {
      if (activeRequestId == requestId && !hasScanResult) {
        Log.w(
          TAG,
          "no scan result within ${NO_RESULT_LOG_DELAY_MS}ms requestId=$requestId bluetooth likely scanning but no advertisements received",
        )
      }
    }
    noResultLogRunnable = runnable
    mainHandler.postDelayed(runnable, NO_RESULT_LOG_DELAY_MS)
  }

  /** 取消待触发的无结果诊断日志。 */
  private fun cancelNoResultLog() {
    val runnable = noResultLogRunnable ?: return
    mainHandler.removeCallbacks(runnable)
    noResultLogRunnable = null
  }

  /** 根据 Flutter 侧扫描条件构建 Android ScanFilter。 */
  private fun buildScanFilters(filter: BleScanFilterDto): List<ScanFilter> {
    if (filter.serviceUuids.isEmpty()) {
      return emptyList()
    }
    return filter.serviceUuids.map {
      ScanFilter.Builder().setServiceUuid(ParcelUuid.fromString(it)).build()
    }
  }

  /** 提取厂商数据并压平为字节数组用于跨端传输。 */
  private fun flattenManufacturerData(result: ScanResult): ByteArray {
    val entries = result.scanRecord?.manufacturerSpecificData ?: return ByteArray(0)
    if (entries.size() == 0) return ByteArray(0)
    var total = 0
    for (i in 0 until entries.size()) {
      total += entries.valueAt(i)?.size ?: 0
    }
    val out = ByteArray(total)
    var offset = 0
    for (i in 0 until entries.size()) {
      val chunk = entries.valueAt(i) ?: continue
      System.arraycopy(chunk, 0, out, offset, chunk.size)
      offset += chunk.size
    }
    return out
  }
}

/** 获取当前上下文下的蓝牙适配器。 */
private fun Context.bluetoothAdapterOrNull(): BluetoothAdapter? {
  val manager = getSystemService(BluetoothManager::class.java)
  return manager?.adapter
}
