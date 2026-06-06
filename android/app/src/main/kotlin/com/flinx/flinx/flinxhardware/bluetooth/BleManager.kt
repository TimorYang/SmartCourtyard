package com.flinx.flinx.flinxhardware.bluetooth

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
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
import com.flinx.flinx.flinxhardware.bridge.BleCharacteristicDto
import com.flinx.flinx.flinxhardware.bridge.BleAuthenticationResultDto
import com.flinx.flinx.flinxhardware.bridge.BleConnectionEventDto
import com.flinx.flinx.flinxhardware.bridge.BleConnectionStateDto
import com.flinx.flinx.flinxhardware.bridge.BleDeviceDto
import com.flinx.flinx.flinxhardware.bridge.BleNotificationDto
import com.flinx.flinx.flinxhardware.bridge.BleReadResultDto
import com.flinx.flinx.flinxhardware.bridge.BleScanFilterDto
import com.flinx.flinx.flinxhardware.bridge.BleServiceDto
import com.flinx.flinx.flinxhardware.bridge.BleServicesDto
import com.flinx.flinx.flinxhardware.bridge.BleWriteResultDto
import com.flinx.flinx.flinxhardware.bridge.BleWriteTypeDto
import com.flinx.flinx.flinxhardware.bridge.FlutterError
import com.flinx.flinx.flinxhardware.protocol.DeviceBleAesKeyCandidate
import com.flinx.flinx.flinxhardware.protocol.DeviceBleFrame
import com.flinx.flinx.flinxhardware.protocol.DeviceBleProtocolConfig
import java.time.Instant
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong

/** BLE 管理器：负责扫描、连接以及 GATT 读写通知的生命周期。 */
class BleManager(
  private val context: Context,
) {
  companion object {
    private const val TAG = "BleManager"
    private const val NO_RESULT_LOG_DELAY_MS = 5_000L
    private const val MAX_RECONNECT_ATTEMPTS = 3
    private const val RECONNECT_DELAY_MS = 2_000L
    private const val AUTH_TIMEOUT_MS = 10_000L
    private const val AUTH_SERVICE_DISCOVERY_TIMEOUT_MS = 8_000L
    private const val DESIRED_MTU = 185
    private const val MTU_FALLBACK_DISCOVERY_DELAY_MS = 1_500L
    private val cccdUuid: UUID =
      UUID.fromString("00002902-0000-1000-8000-00805F9B34FB")
  }

  var onNotification: ((BleNotificationDto) -> Unit)? = null

  private val mainHandler = Handler(Looper.getMainLooper())
  private val notificationSequence = AtomicLong(0)

  private var scanner: BluetoothLeScanner? = null
  private var activeScanCallback: ScanCallback? = null
  private var activeRequestId: String? = null
  private var hasScanResult = false
  private var onDeviceFound: ((BleDeviceDto) -> Unit)? = null
  private var onError: ((FlutterError) -> Unit)? = null
  private var noResultLogRunnable: Runnable? = null

  private val gattMap = ConcurrentHashMap<String, BluetoothGatt>()
  private val connectCallbacks =
    ConcurrentHashMap<String, (Result<BleConnectionEventDto>) -> Unit>()
  private val disconnectCallbacks =
    ConcurrentHashMap<String, (Result<BleConnectionEventDto>) -> Unit>()
  private val discoverServicesCallbacks =
    ConcurrentHashMap<String, (Result<BleServicesDto>) -> Unit>()
  private val readCallbacks =
    ConcurrentHashMap<String, PendingRead>()
  private val writeCallbacks =
    ConcurrentHashMap<String, PendingWrite>()
  private val notifyCallbacks =
    ConcurrentHashMap<String, PendingNotifyChange>()
  private val authSessions =
    ConcurrentHashMap<String, PendingAuthentication>()
  private val pendingAuthDiscoveries =
    ConcurrentHashMap<String, PendingAuthenticationDiscovery>()
  private val notificationBuffers =
    ConcurrentHashMap<String, ByteArray>()
  private val requestIdsByDevice = ConcurrentHashMap<String, String>()
  private val reconnectAttempts = ConcurrentHashMap<String, Int>()
  private val reconnectRunnables = ConcurrentHashMap<String, Runnable>()
  private val explicitDisconnects = ConcurrentHashMap.newKeySet<String>()
  private val serviceDiscoveryInProgress = ConcurrentHashMap.newKeySet<String>()
  private val mtuFallbackRunnables = ConcurrentHashMap<String, Runnable>()

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
      "开始扫描 requestId=$requestId manufacturer=${Build.MANUFACTURER} model=${Build.MODEL} sdk=${Build.VERSION.SDK_INT} serviceUuids=${filter.serviceUuids} namePrefix=${filter.namePrefix} exactName=${filter.exactName} allowDuplicates=${filter.allowDuplicates}",
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
    bleScanner.startScan(filters, settings, callback)
    scheduleNoResultLog(requestId)
  }

  /** 停止当前 BLE 扫描。 */
  @SuppressLint("MissingPermission")
  fun stopScan(requestId: String) {
    cancelNoResultLog()
    val callback = activeScanCallback
    val currentScanner = scanner
    if (callback != null && currentScanner != null) {
      Log.d(TAG, "停止扫描 requestId=$requestId activeRequestId=$activeRequestId")
      currentScanner.stopScan(callback)
    }
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
    explicitDisconnects.remove(deviceId)
    cancelPendingReconnect(deviceId, resetAttempts = true)
    cancelMtuFallbackDiscovery(deviceId)
    removeAuthSession(deviceId)
    removePendingAuthDiscovery(deviceId)
    requestIdsByDevice[deviceId] = requestId
    connectCallbacks[deviceId] = callback
    onConnectionChanged(
      BleConnectionEventDto(
        requestId = requestId,
        deviceId = deviceId,
        state = BleConnectionStateDto.CONNECTING,
      ),
    )
    startGattConnection(
      requestId = requestId,
      device = device,
      onConnectionChanged = onConnectionChanged,
      reconnectAttempt = null,
    )
  }

  /** 断开 BLE 设备连接，并在断开完成时回调结果。 */
  @SuppressLint("MissingPermission")
  fun disconnectDevice(
    requestId: String,
    deviceId: String,
    onConnectionChanged: (BleConnectionEventDto) -> Unit,
    callback: (Result<BleConnectionEventDto>) -> Unit,
  ) {
    explicitDisconnects.add(deviceId)
    cancelPendingReconnect(deviceId, resetAttempts = true)
    cancelMtuFallbackDiscovery(deviceId)
    val gatt = gattMap[deviceId]
      ?: run {
        requestIdsByDevice.remove(deviceId)
        connectCallbacks.remove(deviceId)
        removeAuthSession(deviceId)
        removePendingAuthDiscovery(deviceId)
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
    removeAuthSession(deviceId)
    removePendingAuthDiscovery(deviceId)
    Log.d(TAG, "主动断开设备 requestId=$requestId deviceId=$deviceId")
    gatt.disconnect()
    onConnectionChanged(
      BleConnectionEventDto(
        requestId = requestId,
        deviceId = deviceId,
        state = BleConnectionStateDto.DISCONNECTED,
      ),
    )
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
    Log.d(TAG, "开始发现服务 requestId=$requestId deviceId=$deviceId")
    if (!startServiceDiscovery(requestId, deviceId, gatt, "manual")) {
      discoverServicesCallbacks.remove(deviceId)
      throw FlutterError("service_discovery_failed", "Failed to start GATT service discovery.")
    }
  }

  /** 读取特征值。 */
  @SuppressLint("MissingPermission")
  fun readCharacteristic(
    requestId: String,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    callback: (Result<BleReadResultDto>) -> Unit,
  ) {
    val gatt = gattMap[deviceId]
      ?: throw FlutterError("bluetooth_disconnected", "BLE device is not connected.")
    val characteristic = resolveCharacteristic(gatt, serviceUuid, characteristicUuid)
    val key = characteristicKey(deviceId, characteristic)
    if (readCallbacks[key] != null) {
      throw FlutterError("operation_in_progress", "Read operation is already in progress.")
    }
    requestIdsByDevice[deviceId] = requestId
    readCallbacks[key] = PendingRead(
      requestId = requestId,
      deviceId = deviceId,
      serviceUuid = serviceUuid,
      characteristicUuid = characteristicUuid,
      callback = callback,
    )
    logBlePayload(
      direction = "READ_REQUEST",
      requestId = requestId,
      deviceId = deviceId,
      serviceUuid = serviceUuid,
      characteristicUuid = characteristicUuid,
    )
    if (!gatt.readCharacteristic(characteristic)) {
      readCallbacks.remove(key)
      throw FlutterError("read_characteristic_failed", "Failed to start characteristic read.")
    }
  }

  /** 写入特征值。 */
  @SuppressLint("MissingPermission")
  fun writeCharacteristic(
    requestId: String,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    payload: ByteArray,
    writeType: BleWriteTypeDto,
    callback: (Result<BleWriteResultDto>) -> Unit,
  ) {
    val gatt = gattMap[deviceId]
      ?: throw FlutterError("bluetooth_disconnected", "BLE device is not connected.")
    val characteristic = resolveCharacteristic(gatt, serviceUuid, characteristicUuid)
    requestIdsByDevice[deviceId] = requestId
    characteristic.writeType = when (writeType) {
      BleWriteTypeDto.WITH_RESPONSE -> BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
      BleWriteTypeDto.WITHOUT_RESPONSE -> BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
    }
    characteristic.value = payload
    val key = characteristicKey(deviceId, characteristic)
    logBlePayload(
      direction = "WRITE_REQUEST",
      requestId = requestId,
      deviceId = deviceId,
      serviceUuid = serviceUuid,
      characteristicUuid = characteristicUuid,
      payload = payload,
    )
    if (characteristic.writeType == BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT) {
      if (writeCallbacks[key] != null) {
        throw FlutterError("operation_in_progress", "Write operation is already in progress.")
      }
      writeCallbacks[key] = PendingWrite(
        requestId = requestId,
        deviceId = deviceId,
        serviceUuid = serviceUuid,
        characteristicUuid = characteristicUuid,
        callback = callback,
      )
    }
    if (!gatt.writeCharacteristic(characteristic)) {
      writeCallbacks.remove(key)
      throw FlutterError("write_characteristic_failed", "Failed to start characteristic write.")
    }
    if (characteristic.writeType == BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE) {
      callback(
        Result.success(
          BleWriteResultDto(
            requestId = requestId,
            deviceId = deviceId,
            serviceUuid = serviceUuid,
            characteristicUuid = characteristicUuid,
            accepted = true,
            nativeCode = "write_without_response",
          ),
        ),
      )
    }
  }

  /** 开关特征通知。 */
  @SuppressLint("MissingPermission")
  fun setCharacteristicNotify(
    requestId: String,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    enabled: Boolean,
    callback: (Result<BleWriteResultDto>) -> Unit,
  ) {
    val gatt = gattMap[deviceId]
      ?: throw FlutterError("bluetooth_disconnected", "BLE device is not connected.")
    val characteristic = resolveCharacteristic(gatt, serviceUuid, characteristicUuid)
    val key = characteristicKey(deviceId, characteristic)
    if (notifyCallbacks[key] != null) {
      throw FlutterError("operation_in_progress", "Notify operation is already in progress.")
    }
    requestIdsByDevice[deviceId] = requestId
    Log.d(
      TAG,
      "设置通知 requestId=$requestId deviceId=$deviceId service=$serviceUuid characteristic=$characteristicUuid enabled=$enabled",
    )
    val localEnabled = gatt.setCharacteristicNotification(characteristic, enabled)
    if (!localEnabled) {
      throw FlutterError("set_notify_failed", "Failed to change local notification state.")
    }

    val descriptor = characteristic.getDescriptor(cccdUuid)
    if (descriptor == null) {
      callback(
        Result.success(
          BleWriteResultDto(
            requestId = requestId,
            deviceId = deviceId,
            serviceUuid = serviceUuid,
            characteristicUuid = characteristicUuid,
            accepted = true,
            nativeCode = "notify_local_only",
          ),
        ),
      )
      return
    }

    descriptor.value =
      if (enabled) BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
      else BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
    notifyCallbacks[key] = PendingNotifyChange(
      requestId = requestId,
      deviceId = deviceId,
      serviceUuid = serviceUuid,
      characteristicUuid = characteristicUuid,
      callback = callback,
    )
    if (!gatt.writeDescriptor(descriptor)) {
      notifyCallbacks.remove(key)
      throw FlutterError("set_notify_failed", "Failed to write CCCD descriptor.")
    }
  }

  /** 显式发起设备协议鉴权。连接成功后由 Flutter 调用，避免连接生命周期里隐式发送 0x0E03。 */
  @SuppressLint("MissingPermission")
  fun authenticateDevice(
    requestId: String,
    deviceId: String,
    token: String,
    callback: (Result<BleAuthenticationResultDto>) -> Unit,
  ) {
    val gatt = gattMap[deviceId]
      ?: throw FlutterError("bluetooth_disconnected", "BLE device is not connected.")
    requestIdsByDevice[deviceId] = requestId
    if (gatt.getService(DeviceBleProtocolConfig.communicationServiceUuid) == null) {
      waitForAuthenticationServiceDiscovery(
        requestId = requestId,
        deviceId = deviceId,
        gatt = gatt,
        token = token,
        callback = callback,
      )
      return
    }
    startAuthentication(
      requestId = requestId,
      deviceId = deviceId,
      gatt = gatt,
      token = token,
      callback = callback,
    )
  }

  @SuppressLint("MissingPermission")
  private fun waitForAuthenticationServiceDiscovery(
    requestId: String,
    deviceId: String,
    gatt: BluetoothGatt,
    token: String,
    callback: (Result<BleAuthenticationResultDto>) -> Unit,
  ) {
    if (pendingAuthDiscoveries.containsKey(deviceId)) {
      callback(
        Result.failure(
          FlutterError(
            "operation_in_progress",
            "BLE authentication is waiting for service discovery.",
            "deviceId=$deviceId",
          ),
        ),
      )
      return
    }
    val pending = PendingAuthenticationDiscovery(
      requestId = requestId,
      deviceId = deviceId,
      token = token,
      callback = callback,
    )
    val timeoutRunnable = Runnable {
      val removed = pendingAuthDiscoveries.remove(deviceId) ?: return@Runnable
      removed.callback(
        Result.failure(
          FlutterError(
            "service_discovery_timeout",
            "BLE provisioning service discovery timed out.",
            "requestId=${removed.requestId},deviceId=$deviceId",
          ),
        ),
      )
    }
    pending.timeoutRunnable = timeoutRunnable
    pendingAuthDiscoveries[deviceId] = pending
    mainHandler.postDelayed(timeoutRunnable, AUTH_SERVICE_DISCOVERY_TIMEOUT_MS)
    Log.d(TAG, "鉴权等待服务发现 requestId=$requestId deviceId=$deviceId")
    if (!startServiceDiscovery(requestId, deviceId, gatt, "auth")) {
      removePendingAuthDiscovery(deviceId)
      callback(
        Result.failure(
          FlutterError(
            "service_discovery_failed",
            "Failed to start GATT service discovery.",
            "deviceId=$deviceId",
          ),
        ),
      )
    }
  }

  @SuppressLint("MissingPermission")
  private fun startServiceDiscovery(
    requestId: String,
    deviceId: String,
    gatt: BluetoothGatt,
    reason: String,
  ): Boolean {
    if (!serviceDiscoveryInProgress.add(deviceId)) {
      Log.d(TAG, "等待已有服务发现流程 requestId=$requestId deviceId=$deviceId reason=$reason")
      return true
    }
    if (!gatt.discoverServices()) {
      serviceDiscoveryInProgress.remove(deviceId)
      return false
    }
    return true
  }

  @SuppressLint("MissingPermission")
  private fun startInitialServiceDiscovery(
    requestId: String,
    deviceId: String,
    gatt: BluetoothGatt,
    reason: String,
  ) {
    Log.d(TAG, "开始发现服务 requestId=$requestId deviceId=$deviceId reason=$reason")
    if (!startServiceDiscovery(requestId, deviceId, gatt, reason)) {
      Log.w(TAG, "发现服务启动失败 requestId=$requestId deviceId=$deviceId reason=$reason")
    }
  }

  @SuppressLint("MissingPermission")
  private fun startGattConnection(
    requestId: String,
    device: BluetoothDevice,
    onConnectionChanged: (BleConnectionEventDto) -> Unit,
    reconnectAttempt: Int?,
  ) {
    val reconnectSuffix = reconnectAttempt?.let { " reconnectAttempt=$it" } ?: ""
    Log.d(
      TAG,
      "发起连接 requestId=$requestId deviceId=${device.address} name=${device.name ?: ""}$reconnectSuffix",
    )
    val gatt = device.connectGatt(
      context,
      false,
      createGattCallback(device, onConnectionChanged),
      BluetoothDevice.TRANSPORT_LE,
    )
    gattMap[device.address] = gatt
  }

  private fun cancelPendingReconnect(deviceId: String, resetAttempts: Boolean) {
    reconnectRunnables.remove(deviceId)?.let(mainHandler::removeCallbacks)
    if (resetAttempts) {
      reconnectAttempts.remove(deviceId)
    }
  }

  private fun scheduleMtuFallbackDiscovery(
    requestId: String,
    deviceId: String,
    gatt: BluetoothGatt,
  ) {
    cancelMtuFallbackDiscovery(deviceId)
    val runnable = Runnable {
      mtuFallbackRunnables.remove(deviceId)
      if (!gattMap.containsKey(deviceId)) {
        return@Runnable
      }
      Log.w(TAG, "请求MTU未收到回调，兜底发现服务 requestId=$requestId deviceId=$deviceId")
      startInitialServiceDiscovery(requestId, deviceId, gatt, reason = "mtu_timeout")
    }
    mtuFallbackRunnables[deviceId] = runnable
    mainHandler.postDelayed(runnable, MTU_FALLBACK_DISCOVERY_DELAY_MS)
  }

  private fun cancelMtuFallbackDiscovery(deviceId: String) {
    mtuFallbackRunnables.remove(deviceId)?.let(mainHandler::removeCallbacks)
  }

  private fun scheduleReconnect(
    requestId: String,
    device: BluetoothDevice,
    onConnectionChanged: (BleConnectionEventDto) -> Unit,
  ) {
    val deviceId = device.address
    val nextAttempt = (reconnectAttempts[deviceId] ?: 0) + 1
    reconnectAttempts[deviceId] = nextAttempt
    val runnable = Runnable {
      reconnectRunnables.remove(deviceId)
      val bluetoothAdapter = context.bluetoothAdapterOrNull()
      if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
        Log.w(TAG, "取消重连 requestId=$requestId deviceId=$deviceId reason=bluetooth_unavailable")
        return@Runnable
      }
      requestIdsByDevice[deviceId] = requestId
      onConnectionChanged(
        BleConnectionEventDto(
          requestId = requestId,
          deviceId = deviceId,
          state = BleConnectionStateDto.CONNECTING,
          nativeCode = "reconnect_attempt_$nextAttempt",
        ),
      )
      startGattConnection(
        requestId = requestId,
        device = device,
        onConnectionChanged = onConnectionChanged,
        reconnectAttempt = nextAttempt,
      )
    }
    cancelPendingReconnect(deviceId, resetAttempts = false)
    reconnectRunnables[deviceId] = runnable
    mainHandler.postDelayed(runnable, RECONNECT_DELAY_MS)
  }

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
          "蓝牙连接状态 requestId=$requestId deviceId=$deviceId status=$status state=${describeConnectionState(newState)}",
        )
        when (newState) {
          BluetoothProfile.STATE_CONNECTED -> {
            explicitDisconnects.remove(deviceId)
            cancelPendingReconnect(deviceId, resetAttempts = true)
            val event = BleConnectionEventDto(
              requestId = requestId,
              deviceId = deviceId,
              state = BleConnectionStateDto.CONNECTED,
              nativeCode = status.toString(),
            )
            gattMap[deviceId] = gatt
            onConnectionChanged(event)
            connectCallbacks.remove(deviceId)?.invoke(Result.success(event))
            Log.d(TAG, "蓝牙连接成功，开始请求MTU requestId=$requestId deviceId=$deviceId mtu=$DESIRED_MTU")
            if (!gatt.requestMtu(DESIRED_MTU)) {
              Log.w(TAG, "请求MTU启动失败，直接发现服务 requestId=$requestId deviceId=$deviceId mtu=$DESIRED_MTU")
              startInitialServiceDiscovery(requestId, deviceId, gatt, reason = "connect_mtu_start_failed")
            } else {
              scheduleMtuFallbackDiscovery(requestId, deviceId, gatt)
            }
          }
          BluetoothProfile.STATE_DISCONNECTED -> {
            gatt.close()
            gattMap.remove(deviceId)
            cancelMtuFallbackDiscovery(deviceId)
            serviceDiscoveryInProgress.remove(deviceId)
            discoverServicesCallbacks.remove(deviceId)
            failPendingOperations(deviceId, status)
            val event = BleConnectionEventDto(
              requestId = requestId,
              deviceId = deviceId,
              state = BleConnectionStateDto.DISCONNECTED,
              nativeCode = status.toString(),
            )
            onConnectionChanged(event)
            val explicitDisconnect = explicitDisconnects.remove(deviceId)
            val reconnectAttempt = reconnectAttempts[deviceId] ?: 0
            val shouldReconnect =
              !explicitDisconnect &&
              disconnectCallbacks[deviceId] == null &&
              reconnectAttempt < MAX_RECONNECT_ATTEMPTS
            if (shouldReconnect) {
              scheduleReconnect(requestId, device, onConnectionChanged)
              return
            }
            cancelPendingReconnect(deviceId, resetAttempts = true)
            val disconnectCallback = disconnectCallbacks.remove(deviceId)
            if (disconnectCallback != null) {
              disconnectCallback(Result.success(event))
            } else {
              connectCallbacks.remove(deviceId)?.invoke(Result.success(event))
            }
            requestIdsByDevice.remove(deviceId)
          }
        }
      }

      override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
        val deviceId = device.address
        val requestId = requestIdsByDevice[deviceId] ?: "unknown"
        cancelMtuFallbackDiscovery(deviceId)
        Log.d(TAG, "蓝牙MTU变更 requestId=$requestId deviceId=$deviceId mtu=$mtu status=$status")
        startInitialServiceDiscovery(requestId, deviceId, gatt, reason = "mtu_changed")
      }

      override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
        val deviceId = device.address
        val requestId = requestIdsByDevice[deviceId] ?: "unknown"
        serviceDiscoveryInProgress.remove(deviceId)
        val callback = discoverServicesCallbacks.remove(deviceId)
        Log.d(
          TAG,
          "蓝牙服务发现完成 requestId=$requestId deviceId=$deviceId status=$status serviceCount=${gatt.services.size}",
        )
        if (status != BluetoothGatt.GATT_SUCCESS) {
          removePendingAuthDiscovery(deviceId)?.callback(
            Result.failure(
              FlutterError(
                "service_discovery_failed",
                "GATT 服务发现失败。",
                "status=$status,deviceId=$deviceId",
              ),
            ),
          )
          callback?.invoke(
            Result.failure(
              FlutterError(
                "service_discovery_failed",
                "GATT 服务发现失败。",
                "status=$status,deviceId=$deviceId",
              ),
            ),
          )
          return
        }
        logDiscoveredServices(requestId, deviceId, gatt)
        removePendingAuthDiscovery(deviceId)?.let { pendingAuth ->
          startAuthentication(
            requestId = pendingAuth.requestId,
            deviceId = deviceId,
            gatt = gatt,
            token = pendingAuth.token,
            callback = pendingAuth.callback,
          )
        }
        callback?.invoke(Result.success(mapServices(requestId, deviceId, gatt)))
      }

      @SuppressLint("MissingPermission")
      override fun onCharacteristicChanged(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
      ) {
        handleCharacteristicChanged(gatt, characteristic, characteristic.value ?: ByteArray(0))
      }

      override fun onCharacteristicChanged(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        value: ByteArray,
      ) {
        handleCharacteristicChanged(gatt, characteristic, value)
      }

      private fun handleCharacteristicChanged(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        payload: ByteArray,
      ) {
        val deviceId = device.address
        val requestId = requestIdsByDevice[deviceId]
        val serviceUuid = characteristic.service.uuid.toString()
        val characteristicUuid = characteristic.uuid.toString()
        val reassembledPayloads = reassembleNotificationPayloads(
          deviceId = deviceId,
          serviceUuid = serviceUuid,
          characteristicUuid = characteristicUuid,
          payload = payload,
        )
        if (reassembledPayloads.isEmpty()) {
          Log.d(
            TAG,
            "蓝牙接收分片 requestId=${requestId ?: "unknown"} deviceId=$deviceId service=$serviceUuid characteristic=$characteristicUuid chunkLen=${payload.size} chunkHex=${toHexOrEmpty(payload)}",
          )
          return
        }
        reassembledPayloads.forEach { framePayload ->
          logBlePayload(
            direction = "NOTIFY",
            requestId = requestId,
            deviceId = deviceId,
            serviceUuid = serviceUuid,
            characteristicUuid = characteristicUuid,
            payload = framePayload,
          )
          handleAuthenticationNotification(
            requestId = requestId,
            deviceId = deviceId,
            serviceUuid = serviceUuid,
            characteristicUuid = characteristicUuid,
            payload = framePayload,
          )
          logEncryptedPayloadAnalysis(
            requestId = requestId,
            deviceId = deviceId,
            serviceUuid = serviceUuid,
            characteristicUuid = characteristicUuid,
            payload = framePayload,
          )
          emitNotification(
            requestId = requestId,
            deviceId = deviceId,
            serviceUuid = serviceUuid,
            characteristicUuid = characteristicUuid,
            payload = framePayload,
          )
        }
      }

      @SuppressLint("MissingPermission")
      override fun onCharacteristicRead(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        status: Int,
      ) {
        val deviceId = device.address
        val key = characteristicKey(deviceId, characteristic)
        val pending = readCallbacks.remove(key) ?: return
        val payload = characteristic.value ?: ByteArray(0)
        logBlePayload(
          direction = "READ_RESPONSE",
          requestId = pending.requestId,
          deviceId = deviceId,
          serviceUuid = pending.serviceUuid,
          characteristicUuid = pending.characteristicUuid,
          payload = payload,
          status = status,
        )
        if (status != BluetoothGatt.GATT_SUCCESS) {
          pending.callback(
            Result.failure(
              FlutterError(
                "read_characteristic_failed",
                "Failed to read characteristic.",
                "status=$status,deviceId=$deviceId",
              ),
            ),
          )
          return
        }
        pending.callback(
          Result.success(
            BleReadResultDto(
              requestId = pending.requestId,
              deviceId = deviceId,
              serviceUuid = pending.serviceUuid,
              characteristicUuid = pending.characteristicUuid,
              payload = payload,
            ),
          ),
        )
      }

      @SuppressLint("MissingPermission")
      override fun onCharacteristicWrite(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        status: Int,
      ) {
        val deviceId = device.address
        val key = characteristicKey(deviceId, characteristic)
        val pending = writeCallbacks.remove(key) ?: return
        logBlePayload(
          direction = "WRITE_RESPONSE",
          requestId = pending.requestId,
          deviceId = deviceId,
          serviceUuid = pending.serviceUuid,
          characteristicUuid = pending.characteristicUuid,
          payload = characteristic.value ?: ByteArray(0),
          status = status,
        )
        if (status != BluetoothGatt.GATT_SUCCESS) {
          pending.callback(
            Result.failure(
              FlutterError(
                "write_characteristic_failed",
                "Failed to write characteristic.",
                "status=$status,deviceId=$deviceId",
              ),
            ),
          )
          return
        }
        pending.callback(
          Result.success(
            BleWriteResultDto(
              requestId = pending.requestId,
              deviceId = deviceId,
              serviceUuid = pending.serviceUuid,
              characteristicUuid = pending.characteristicUuid,
              accepted = true,
              nativeCode = status.toString(),
            ),
          ),
        )
      }

      @SuppressLint("MissingPermission")
      override fun onDescriptorWrite(
        gatt: BluetoothGatt,
        descriptor: BluetoothGattDescriptor,
        status: Int,
      ) {
        val deviceId = device.address
        val characteristic = descriptor.characteristic
        maybeContinueAuthenticationAfterNotify(deviceId, gatt, descriptor, status)
        val key = characteristicKey(deviceId, characteristic)
        val pending = notifyCallbacks.remove(key) ?: return
        Log.d(
          TAG,
          "蓝牙通知配置结果 requestId=${pending.requestId} deviceId=$deviceId service=${pending.serviceUuid} characteristic=${pending.characteristicUuid} descriptor=${descriptor.uuid} status=$status value=${toHexOrEmpty(descriptor.value)}",
        )
        if (status != BluetoothGatt.GATT_SUCCESS) {
          pending.callback(
            Result.failure(
              FlutterError(
                "set_notify_failed",
                "Failed to update characteristic notify state.",
                "status=$status,deviceId=$deviceId",
              ),
            ),
          )
          return
        }
        pending.callback(
          Result.success(
            BleWriteResultDto(
              requestId = pending.requestId,
              deviceId = deviceId,
              serviceUuid = pending.serviceUuid,
              characteristicUuid = pending.characteristicUuid,
              accepted = true,
              nativeCode = status.toString(),
            ),
          ),
        )
      }
    }
  }

  private fun logEncryptedPayloadAnalysis(
    requestId: String?,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    payload: ByteArray,
  ) {
    if (!serviceUuid.equals(DeviceBleProtocolConfig.communicationServiceUuid.toString(), ignoreCase = true)) {
      return
    }
    val encryptedPayload = extractEncryptedPayload(payload) ?: return
    val candidates = DeviceBleProtocolConfig.candidateAesKeys()
    val analyses = candidates.joinToString(separator = " | ") { candidate ->
      describeAesCandidate(candidate, encryptedPayload)
    }
    Log.d(
      TAG,
      "蓝牙接收密文分析 requestId=${requestId ?: "unknown"} deviceId=$deviceId service=$serviceUuid characteristic=$characteristicUuid cipherLen=${encryptedPayload.size} cipherHex=${toHexOrEmpty(encryptedPayload)} analyses=$analyses",
    )
  }

  private fun extractEncryptedPayload(payload: ByteArray): ByteArray? {
    if (payload.size < 8) {
      return null
    }
    val header = ((payload[0].toInt() and 0xFF) shl 8) or (payload[1].toInt() and 0xFF)
    if (header != DeviceBleProtocolConfig.frameHeader) {
      return null
    }
    val cryptoType = payload[4].toInt() and 0xFF
    if (cryptoType != DeviceBleProtocolConfig.cryptoAes128) {
      return null
    }
    val hasFooter =
      payload.size >= 8 &&
      payload[payload.size - 2] == 0xAA.toByte() &&
      payload[payload.size - 1] == 0xAA.toByte()
    val payloadEndExclusive = if (hasFooter) payload.size - 3 else payload.size
    if (payloadEndExclusive <= 5) {
      return null
    }
    return payload.copyOfRange(5, payloadEndExclusive)
  }

  private fun describeAesCandidate(
    candidate: DeviceBleAesKeyCandidate,
    cipherBytes: ByteArray,
  ): String {
    val ecbPkcs7 = DeviceBleProtocolConfig.tryDecryptAesEcbPkcs7(cipherBytes, candidate.keyBytes)
    val cbcPkcs7 = DeviceBleProtocolConfig.tryDecryptAesCbcPkcs7ZeroIv(cipherBytes, candidate.keyBytes)
    return buildString {
      append(candidate.label)
      append("{ecbPkcs7=")
      append(ecbPkcs7?.let(::toHexOrEmpty) ?: "fail")
      append(", cbcPkcs7ZeroIv=")
      append(cbcPkcs7?.let(::toHexOrEmpty) ?: "fail")
      append("}")
    }
  }

  @SuppressLint("MissingPermission")
  private fun startAuthentication(
    requestId: String,
    deviceId: String,
    gatt: BluetoothGatt,
    token: String,
    callback: (Result<BleAuthenticationResultDto>) -> Unit,
  ) {
    if (authSessions.containsKey(deviceId)) {
      callback(
        Result.failure(
          FlutterError(
            "operation_in_progress",
            "BLE authentication is already in progress.",
            "deviceId=$deviceId",
          ),
        ),
      )
      return
    }
    val service = gatt.getService(DeviceBleProtocolConfig.communicationServiceUuid)
    if (service == null) {
      callback(
        Result.failure(
          FlutterError(
            "service_not_found",
            "BLE provisioning service was not discovered.",
            "deviceId=$deviceId",
          ),
        ),
      )
      return
    }
    val notifyCharacteristic = service.getCharacteristic(DeviceBleProtocolConfig.notifyCharacteristicUuid)
    val writeCharacteristic = service.getCharacteristic(DeviceBleProtocolConfig.writeCharacteristicUuid)
    if (notifyCharacteristic == null || writeCharacteristic == null) {
      Log.w(
        TAG,
        "鉴权失败 requestId=$requestId deviceId=$deviceId reason=协议特征缺失 hasNotify=${notifyCharacteristic != null} hasWrite=${writeCharacteristic != null}",
      )
      callback(
        Result.failure(
          FlutterError(
            "characteristic_not_found",
            "BLE provisioning characteristics were not discovered.",
            "deviceId=$deviceId",
          ),
        ),
      )
      return
    }
    val sequence = nextProtocolSequence()
    val payload = runCatching {
      DeviceBleProtocolConfig.buildAuthenticationFrame(
        sequence = sequence,
        utcTimestampSeconds = Instant.now().epochSecond,
        tokenMd5 = token.trim(),
      )
    }.getOrElse { error ->
      callback(
        Result.failure(
          FlutterError(
            "invalid_auth_token",
            error.message ?: "BLE auth token is invalid.",
            "deviceId=$deviceId",
          ),
        ),
      )
      return
    }
    val auth = PendingAuthentication(
      requestId = requestId,
      deviceId = deviceId,
      sequence = sequence,
      serviceUuid = service.uuid.toString(),
      notifyCharacteristicUuid = notifyCharacteristic.uuid.toString(),
      writeCharacteristicUuid = writeCharacteristic.uuid.toString(),
      payload = payload,
      callback = callback,
    )
    authSessions[deviceId] = auth
    val timeoutRunnable = Runnable {
      val pending = authSessions.remove(deviceId) ?: return@Runnable
      pending.callback(
        Result.failure(
          FlutterError(
            "command_timeout",
            "BLE authentication timed out.",
            "requestId=${pending.requestId},deviceId=$deviceId,sequence=${pending.sequence}",
          ),
        ),
      )
    }
    auth.timeoutRunnable = timeoutRunnable
    mainHandler.postDelayed(timeoutRunnable, AUTH_TIMEOUT_MS)
    Log.d(
      TAG,
      "鉴权准备 requestId=$requestId deviceId=$deviceId seq=0x${sequence.toString(16).padStart(4, '0')}",
    )
    val localEnabled = gatt.setCharacteristicNotification(notifyCharacteristic, true)
    if (!localEnabled) {
      Log.w(TAG, "鉴权失败 requestId=$requestId deviceId=$deviceId step=开启本地通知失败")
      removeAuthSession(deviceId)
      callback(
        Result.failure(
          FlutterError(
            "set_notify_failed",
            "Failed to change local notification state.",
            "deviceId=$deviceId",
          ),
        ),
      )
      return
    }
    val descriptor = notifyCharacteristic.getDescriptor(cccdUuid)
    if (descriptor == null) {
      Log.w(TAG, "鉴权失败 requestId=$requestId deviceId=$deviceId step=缺少CCCD描述符")
      removeAuthSession(deviceId)
      callback(
        Result.failure(
          FlutterError(
            "descriptor_not_found",
            "BLE notification CCCD descriptor was not found.",
            "deviceId=$deviceId",
          ),
        ),
      )
      return
    }
    descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
    Log.d(
      TAG,
      "鉴权开启通知 requestId=$requestId deviceId=$deviceId service=${auth.serviceUuid} characteristic=${auth.notifyCharacteristicUuid}",
    )
    if (!gatt.writeDescriptor(descriptor)) {
      Log.w(TAG, "鉴权失败 requestId=$requestId deviceId=$deviceId step=写入CCCD失败")
      removeAuthSession(deviceId)
      callback(
        Result.failure(
          FlutterError(
            "set_notify_failed",
            "Failed to write CCCD descriptor.",
            "deviceId=$deviceId",
          ),
        ),
      )
    }
  }

  @SuppressLint("MissingPermission")
  private fun maybeContinueAuthenticationAfterNotify(
    deviceId: String,
    gatt: BluetoothGatt,
    descriptor: BluetoothGattDescriptor,
    status: Int,
  ) {
    val auth = authSessions[deviceId] ?: return
    if (!descriptor.characteristic.uuid.toString()
        .equals(auth.notifyCharacteristicUuid, ignoreCase = true)
    ) {
      return
    }
    if (status != BluetoothGatt.GATT_SUCCESS) {
      Log.w(
        TAG,
        "鉴权失败 requestId=${auth.requestId} deviceId=$deviceId step=通知配置回调失败 status=$status",
      )
      removeAuthSession(deviceId)
      auth.callback(
        Result.failure(
          FlutterError(
            "set_notify_failed",
            "Failed to update characteristic notify state.",
            "status=$status,deviceId=$deviceId",
          ),
        ),
      )
      return
    }
    val writeCharacteristic = gatt.getService(UUID.fromString(auth.serviceUuid))
      ?.getCharacteristic(UUID.fromString(auth.writeCharacteristicUuid))
    if (writeCharacteristic == null) {
      Log.w(
        TAG,
        "鉴权失败 requestId=${auth.requestId} deviceId=$deviceId step=鉴权写特征不存在",
      )
      removeAuthSession(deviceId)
      auth.callback(
        Result.failure(
          FlutterError(
            "characteristic_not_found",
            "BLE authentication write characteristic was not found.",
            "deviceId=$deviceId",
          ),
        ),
      )
      return
    }
    writeCharacteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
    writeCharacteristic.value = auth.payload
    logBlePayload(
      direction = "AUTH_WRITE_REQUEST",
      requestId = auth.requestId,
      deviceId = deviceId,
      serviceUuid = auth.serviceUuid,
      characteristicUuid = auth.writeCharacteristicUuid,
      payload = auth.payload,
    )
    if (!gatt.writeCharacteristic(writeCharacteristic)) {
      Log.w(
        TAG,
        "鉴权失败 requestId=${auth.requestId} deviceId=$deviceId step=发送鉴权帧失败",
      )
      removeAuthSession(deviceId)
      auth.callback(
        Result.failure(
          FlutterError(
            "write_characteristic_failed",
            "Failed to send BLE authentication frame.",
            "deviceId=$deviceId",
          ),
        ),
      )
      return
    }
    Log.d(
      TAG,
      "鉴权已发送 requestId=${auth.requestId} deviceId=$deviceId seq=0x${auth.sequence.toString(16).padStart(4, '0')}",
    )
  }

  private fun handleAuthenticationNotification(
    requestId: String?,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    payload: ByteArray,
  ) {
    val auth = authSessions[deviceId] ?: return
    if (!serviceUuid.equals(auth.serviceUuid, ignoreCase = true) ||
      !characteristicUuid.equals(auth.notifyCharacteristicUuid, ignoreCase = true)
    ) {
      return
    }
    val frame = parseProvisioningFrame(payload)
    if (frame == null || frame.command != DeviceBleProtocolConfig.commandAuthenticate) {
      return
    }
    val result = frame.data.firstOrNull()?.toInt()?.and(0xFF)
    val bindState = frame.data.getOrNull(1)?.toInt()?.and(0xFF)
    val success = frame.frameType == DeviceBleProtocolConfig.frameTypeResponse &&
      frame.sequence == auth.sequence &&
      result == 0x00
    Log.d(
      TAG,
      "鉴权结果 requestId=${auth.requestId} callbackRequestId=${requestId ?: "unknown"} deviceId=$deviceId success=$success resultHex=${result?.toString(16)?.padStart(2, '0') ?: ""} bindStateHex=${bindState?.toString(16)?.padStart(2, '0') ?: ""} seq=0x${frame.sequence.toString(16).padStart(4, '0')}",
    )
    removeAuthSession(deviceId)
    if (success) {
      auth.completed = true
      auth.callback(
        Result.success(
          BleAuthenticationResultDto(
            requestId = auth.requestId,
            deviceId = deviceId,
            authenticated = true,
            bindingState = bindState?.toLong(),
            nativeCode = "result=0x${result.toString(16).padStart(2, '0')}",
          ),
        ),
      )
    } else {
      auth.callback(
        Result.failure(
          FlutterError(
            "authentication_failed",
            "BLE authentication was rejected by device.",
            "result=$result,bindState=$bindState,deviceId=$deviceId",
          ),
        ),
      )
    }
  }

  private fun removeAuthSession(deviceId: String): PendingAuthentication? {
    val auth = authSessions.remove(deviceId) ?: return null
    auth.timeoutRunnable?.let(mainHandler::removeCallbacks)
    return auth
  }

  private fun removePendingAuthDiscovery(deviceId: String): PendingAuthenticationDiscovery? {
    val pending = pendingAuthDiscoveries.remove(deviceId) ?: return null
    pending.timeoutRunnable?.let(mainHandler::removeCallbacks)
    return pending
  }

  private fun parseProvisioningFrame(payload: ByteArray): DeviceBleFrame? {
    val parsedFrame = DeviceBleProtocolConfig.parseFrame(payload)
    if (parsedFrame != null && parsedFrame.cryptoType == DeviceBleProtocolConfig.cryptoNone) {
      return parsedFrame
    }
    val encryptedPayload = extractEncryptedPayload(payload) ?: return null
    for (candidate in DeviceBleProtocolConfig.candidateAesKeys()) {
      val ecbPlaintext = DeviceBleProtocolConfig.tryDecryptAesEcbPkcs7(encryptedPayload, candidate.keyBytes)
      val ecbFrame = ecbPlaintext?.let {
        DeviceBleProtocolConfig.parseDecryptedPayload(
          plaintext = it,
          cryptoType = DeviceBleProtocolConfig.cryptoAes128,
        )
      }
      if (ecbFrame != null) {
        return ecbFrame
      }
      val cbcPlaintext = DeviceBleProtocolConfig.tryDecryptAesCbcPkcs7ZeroIv(encryptedPayload, candidate.keyBytes)
      val cbcFrame = cbcPlaintext?.let {
        DeviceBleProtocolConfig.parseDecryptedPayload(
          plaintext = it,
          cryptoType = DeviceBleProtocolConfig.cryptoAes128,
        )
      }
      if (cbcFrame != null) {
        return cbcFrame
      }
    }
    return null
  }

  private fun emitNotification(
    requestId: String?,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    payload: ByteArray,
  ) {
    onNotification?.invoke(
      BleNotificationDto(
        requestId = requestId,
        deviceId = deviceId,
        serviceUuid = serviceUuid,
        characteristicUuid = characteristicUuid,
        payload = payload,
        timestampMillis = System.currentTimeMillis(),
        sequenceNumber = notificationSequence.incrementAndGet(),
      ),
    )
  }

  private fun logDiscoveredServices(
    requestId: String,
    deviceId: String,
    gatt: BluetoothGatt,
  ) {
//    gatt.services.forEach { service ->
//      Log.d(
//        TAG,
//        "蓝牙服务详情 requestId=$requestId deviceId=$deviceId service=${service.uuid} matchedProtocol=${DeviceBleProtocolConfig.supportsService(service.uuid.toString())} characteristicCount=${service.characteristics.size}",
//      )
//      service.characteristics.forEach { characteristic ->
//        Log.d(
//          TAG,
//          "蓝牙特征详情 requestId=$requestId deviceId=$deviceId service=${service.uuid} characteristic=${characteristic.uuid} properties=${describeProperties(characteristic.properties)}",
//        )
//      }
//    }
  }

  private fun logBlePayload(
    direction: String,
    requestId: String?,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    payload: ByteArray = ByteArray(0),
    status: Int? = null,
  ) {
    val frameSummary = describeProtocolFrame(serviceUuid, payload)
    val statusPart = status?.let { " status=$it" } ?: ""
    val trafficType = when {
      direction.contains("REQUEST") -> "蓝牙传输"
      direction.contains("RESPONSE") || direction == "NOTIFY" -> "蓝牙接收"
      else -> "蓝牙收发"
    }
    val directionLabel = when (direction) {
      "AUTH_WRITE_REQUEST" -> "鉴权发送"
      "WRITE_REQUEST" -> "写入请求"
      "WRITE_RESPONSE" -> "写入回调"
      "READ_REQUEST" -> "读取请求"
      "READ_RESPONSE" -> "读取回调"
      "NOTIFY" -> "通知回包"
      else -> direction
    }
    Log.d(
      TAG,
      "$trafficType type=$directionLabel requestId=${requestId ?: "unknown"} deviceId=$deviceId service=$serviceUuid characteristic=$characteristicUuid payloadLen=${payload.size} payloadHex=${toHexOrEmpty(payload)}$statusPart$frameSummary",
    )
  }

  private fun describeProtocolFrame(serviceUuid: String, payload: ByteArray): String {
    if (!DeviceBleProtocolConfig.supportsService(serviceUuid) || payload.isEmpty()) {
      return ""
    }
    describeCipherFrame(payload)?.let { return " protocolCipherFrame=$it" }
    val frame = DeviceBleProtocolConfig.parseFrame(payload) ?: return " protocolFrame=未解析"
    return " protocolFrame=${describeFrame(frame)}"
  }

  private fun describeCipherFrame(payload: ByteArray): String? {
    if (payload.size < 8) {
      return null
    }
    val header = ((payload[0].toInt() and 0xFF) shl 8) or (payload[1].toInt() and 0xFF)
    if (header != DeviceBleProtocolConfig.frameHeader) {
      return null
    }
    val declaredLength =
      ((payload[2].toInt() and 0xFF) shl 8) or (payload[3].toInt() and 0xFF)
    val cryptoType = payload[4].toInt() and 0xFF
    if (cryptoType != DeviceBleProtocolConfig.cryptoAes128) {
      return null
    }
    val footerMatches =
      payload.size >= 2 &&
      payload[payload.size - 2].toInt() and 0xFF == 0xAA &&
      payload[payload.size - 1].toInt() and 0xFF == 0xAA
    val cipherStartIndex = 5
    val cipherEndExclusive = if (footerMatches && payload.size >= 8) payload.size - 3 else payload.size
    if (cipherEndExclusive <= cipherStartIndex) {
      return null
    }
    val cipherPayload = payload.copyOfRange(cipherStartIndex, cipherEndExclusive)
    val bccHex = if (footerMatches && payload.size >= 8) {
      "%02X".format(payload[payload.size - 3].toInt() and 0xFF)
    } else {
      ""
    }
    return buildString {
      append("{crypto=0x")
      append(cryptoType.toString(16).padStart(2, '0'))
      append(", declaredLen=0x")
      append(declaredLength.toString(16).padStart(4, '0'))
      append(", actualLen=")
      append(payload.size)
      append(", cipherLen=")
      append(cipherPayload.size)
      append(", cipherHex=")
      append(toHexOrEmpty(cipherPayload))
      if (bccHex.isNotEmpty()) {
        append(", bcc=0x")
        append(bccHex)
      }
      append(", footer=")
      append(if (footerMatches) "AAAA" else "missing")
      append("}")
    }
  }

  private fun describeFrame(frame: DeviceBleFrame): String {
    return buildString {
      append("{frameType=0x")
      append(frame.frameType.toString(16).padStart(2, '0'))
      append(", crypto=0x")
      append(frame.cryptoType.toString(16).padStart(2, '0'))
      append(", seq=0x")
      append(frame.sequence.toString(16).padStart(4, '0'))
      append(", cmd=0x")
      append(frame.command.toString(16).padStart(4, '0'))
      append(", dataLen=")
      append(frame.data.size)
      append(", dataHex=")
      append(toHexOrEmpty(frame.data))
      append("}")
    }
  }

  private fun describeProperties(properties: Int): String {
    val labels = mutableListOf<String>()
    if (properties and BluetoothGattCharacteristic.PROPERTY_READ != 0) labels += "read"
    if (properties and BluetoothGattCharacteristic.PROPERTY_WRITE != 0) labels += "write"
    if (properties and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE != 0) labels += "writeNoRsp"
    if (properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0) labels += "notify"
    if (properties and BluetoothGattCharacteristic.PROPERTY_INDICATE != 0) labels += "indicate"
    return if (labels.isEmpty()) "none($properties)" else labels.joinToString(separator = "|")
  }

  private fun describeConnectionState(state: Int): String {
    return when (state) {
      BluetoothProfile.STATE_DISCONNECTED -> "disconnected"
      BluetoothProfile.STATE_CONNECTING -> "connecting"
      BluetoothProfile.STATE_CONNECTED -> "connected"
      BluetoothProfile.STATE_DISCONNECTING -> "disconnecting"
      else -> "unknown($state)"
    }
  }

  private fun toHexOrEmpty(bytes: ByteArray?): String {
    if (bytes == null || bytes.isEmpty()) return ""
    return DeviceBleProtocolConfig.toHex(bytes)
  }

  private fun reassembleNotificationPayloads(
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    payload: ByteArray,
  ): List<ByteArray> {
    val isProtocolNotify =
      serviceUuid.equals(DeviceBleProtocolConfig.communicationServiceUuid.toString(), ignoreCase = true) &&
      characteristicUuid.equals(DeviceBleProtocolConfig.notifyCharacteristicUuid.toString(), ignoreCase = true)
    if (!isProtocolNotify || payload.isEmpty()) {
      return listOf(payload)
    }

    val bufferKey = "$deviceId/$serviceUuid/$characteristicUuid"
    val merged = (notificationBuffers.remove(bufferKey) ?: ByteArray(0)) + payload
    val frames = mutableListOf<ByteArray>()
    var working = merged

    while (working.isNotEmpty()) {
      val headerIndex = indexOfFrameHeader(working)
      if (headerIndex < 0) {
        return listOf(payload)
      }
      if (headerIndex > 0) {
        Log.d(
          TAG,
          "蓝牙接收丢弃帧头前数据 deviceId=$deviceId service=$serviceUuid characteristic=$characteristicUuid discardLen=$headerIndex discardHex=${toHexOrEmpty(working.copyOfRange(0, headerIndex))}",
        )
        working = working.copyOfRange(headerIndex, working.size)
      }
      if (working.size < 4) {
        notificationBuffers[bufferKey] = working
        return frames
      }
      val header = ((working[0].toInt() and 0xFF) shl 8) or (working[1].toInt() and 0xFF)
      if (header != DeviceBleProtocolConfig.frameHeader) {
        break
      }
      val declaredLength = ((working[2].toInt() and 0xFF) shl 8) or (working[3].toInt() and 0xFF)
      if (declaredLength < 8) {
        Log.w(
          TAG,
          "蓝牙接收帧长度非法 deviceId=$deviceId service=$serviceUuid characteristic=$characteristicUuid declaredLength=$declaredLength bufferHex=${toHexOrEmpty(working)}",
        )
        working = working.copyOfRange(1, working.size)
        continue
      }
      if (working.size < declaredLength) {
        notificationBuffers[bufferKey] = working
        return frames
      }
      val candidate = working.copyOfRange(0, declaredLength)
      if (!DeviceBleProtocolConfig.hasValidEnvelope(candidate)) {
        Log.w(
          TAG,
          "蓝牙接收帧校验失败 deviceId=$deviceId service=$serviceUuid characteristic=$characteristicUuid declaredLength=$declaredLength candidateLen=${candidate.size} candidateHex=${toHexOrEmpty(candidate)}",
        )
        working = working.copyOfRange(1, working.size)
        continue
      }
      frames += candidate
      working = working.copyOfRange(declaredLength, working.size)
    }

    if (frames.isEmpty()) {
      if (merged.size >= 4 && merged[0] == 0x55.toByte() && merged[1] == 0x55.toByte()) {
        notificationBuffers[bufferKey] = merged
        return emptyList()
      }
      return listOf(payload)
    }

    if (working.isNotEmpty()) {
      notificationBuffers[bufferKey] = working
    }
    return frames
  }

  private fun indexOfFrameHeader(bytes: ByteArray): Int {
    for (index in 0 until bytes.size - 1) {
      if (bytes[index] == 0x55.toByte() && bytes[index + 1] == 0x55.toByte()) {
        return index
      }
    }
    return -1
  }

  private fun failPendingOperations(deviceId: String, status: Int) {
    val disconnectError = FlutterError(
      "bluetooth_disconnected",
      "BLE device disconnected during operation.",
      "status=$status,deviceId=$deviceId",
    )
    removePendingAuthDiscovery(deviceId)?.callback(Result.failure(disconnectError))
    removeAuthSession(deviceId)?.callback(Result.failure(disconnectError))
    readCallbacks.entries.removeIf { entry ->
      if (entry.value.deviceId != deviceId) return@removeIf false
      entry.value.callback(Result.failure(disconnectError))
      true
    }
    writeCallbacks.entries.removeIf { entry ->
      if (entry.value.deviceId != deviceId) return@removeIf false
      entry.value.callback(Result.failure(disconnectError))
      true
    }
    notifyCallbacks.entries.removeIf { entry ->
      if (entry.value.deviceId != deviceId) return@removeIf false
      entry.value.callback(Result.failure(disconnectError))
      true
    }
  }

  private fun resolveCharacteristic(
    gatt: BluetoothGatt,
    serviceUuid: String,
    characteristicUuid: String,
  ): BluetoothGattCharacteristic {
    val service = gatt.getService(UUID.fromString(serviceUuid))
      ?: throw FlutterError("service_not_found", "BLE service was not discovered.")
    return service.getCharacteristic(UUID.fromString(characteristicUuid))
      ?: throw FlutterError("characteristic_not_found", "BLE characteristic was not discovered.")
  }

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

  private fun characteristicKey(
    deviceId: String,
    characteristic: BluetoothGattCharacteristic,
  ): String {
    return "$deviceId/${characteristic.service.uuid}/${characteristic.uuid}"
  }

  private fun nextProtocolSequence(): Int {
    val next = (notificationSequence.incrementAndGet() and 0xFFFF).toInt()
    return if (next == 0) 1 else next
  }

  private fun scheduleNoResultLog(requestId: String) {
    cancelNoResultLog()
    val runnable = Runnable {
      if (activeRequestId == requestId && !hasScanResult) {
        Log.w(TAG, "${NO_RESULT_LOG_DELAY_MS}ms 内没有扫描结果 requestId=$requestId")
      }
    }
    noResultLogRunnable = runnable
    mainHandler.postDelayed(runnable, NO_RESULT_LOG_DELAY_MS)
  }

  private fun cancelNoResultLog() {
    val runnable = noResultLogRunnable ?: return
    mainHandler.removeCallbacks(runnable)
    noResultLogRunnable = null
  }

  private fun createScanCallback(requestId: String): ScanCallback {
    return object : ScanCallback() {
      override fun onScanResult(callbackType: Int, result: ScanResult) {
        emitScanResult(requestId, result)
      }

      override fun onBatchScanResults(results: MutableList<ScanResult>) {
        results.forEach { emitScanResult(requestId, it) }
      }

      override fun onScanFailed(errorCode: Int) {
        onError?.invoke(
          FlutterError(
            code = "ble_scan_failed",
            message = "BLE 扫描失败。",
            details = "requestId=$requestId,errorCode=$errorCode",
          ),
        )
      }
    }
  }

  private fun emitScanResult(requestId: String, result: ScanResult) {
    val rawDeviceName = result.device?.name ?: result.scanRecord?.deviceName
    val deviceName = rawDeviceName?.takeIf { it.isNotBlank() && !it.equals("unnamed", ignoreCase = true) }
      ?: return
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
      "蓝牙扫描结果 requestId=$requestId deviceId=${device.id} name=${device.name} rssi=${device.rssi} serviceUuids=${device.advertisementServiceUuids}",
    )
    onDeviceFound?.invoke(device)
  }

  private fun buildScanFilters(filter: BleScanFilterDto): List<ScanFilter> {
    if (filter.serviceUuids.isEmpty()) {
      return emptyList()
    }
    return filter.serviceUuids.map {
      ScanFilter.Builder().setServiceUuid(ParcelUuid.fromString(it)).build()
    }
  }

  private fun flattenManufacturerData(result: ScanResult): ByteArray {
    val entries = result.scanRecord?.manufacturerSpecificData ?: return ByteArray(0)
    if (entries.size() == 0) return ByteArray(0)
    var total = 0
    for (index in 0 until entries.size()) {
      total += entries.valueAt(index)?.size ?: 0
    }
    val out = ByteArray(total)
    var offset = 0
    for (index in 0 until entries.size()) {
      val chunk = entries.valueAt(index) ?: continue
      System.arraycopy(chunk, 0, out, offset, chunk.size)
      offset += chunk.size
    }
    return out
  }
}

private data class PendingRead(
  val requestId: String,
  val deviceId: String,
  val serviceUuid: String,
  val characteristicUuid: String,
  val callback: (Result<BleReadResultDto>) -> Unit,
)

private data class PendingWrite(
  val requestId: String,
  val deviceId: String,
  val serviceUuid: String,
  val characteristicUuid: String,
  val callback: (Result<BleWriteResultDto>) -> Unit,
)

private data class PendingNotifyChange(
  val requestId: String,
  val deviceId: String,
  val serviceUuid: String,
  val characteristicUuid: String,
  val callback: (Result<BleWriteResultDto>) -> Unit,
)

private data class PendingAuthentication(
  val requestId: String,
  val deviceId: String,
  val sequence: Int,
  val serviceUuid: String,
  val notifyCharacteristicUuid: String,
  val writeCharacteristicUuid: String,
  val payload: ByteArray,
  val callback: (Result<BleAuthenticationResultDto>) -> Unit,
  var completed: Boolean = false,
  var timeoutRunnable: Runnable? = null,
)

private data class PendingAuthenticationDiscovery(
  val requestId: String,
  val deviceId: String,
  val token: String,
  val callback: (Result<BleAuthenticationResultDto>) -> Unit,
  var timeoutRunnable: Runnable? = null,
)

private fun Context.bluetoothAdapterOrNull(): BluetoothAdapter? {
  val manager = getSystemService(BluetoothManager::class.java)
  return manager?.adapter
}
