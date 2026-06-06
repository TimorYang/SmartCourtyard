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
  private val requestIdsByDevice = ConcurrentHashMap<String, String>()
  private val reconnectAttempts = ConcurrentHashMap<String, Int>()
  private val reconnectRunnables = ConcurrentHashMap<String, Runnable>()
  private val explicitDisconnects = ConcurrentHashMap.newKeySet<String>()

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
    authSessions.remove(deviceId)
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
    val gatt = gattMap[deviceId]
      ?: run {
        requestIdsByDevice.remove(deviceId)
        connectCallbacks.remove(deviceId)
        authSessions.remove(deviceId)
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
    authSessions.remove(deviceId)
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
    if (!gatt.discoverServices()) {
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
            Log.d(TAG, "蓝牙连接成功，开始发现服务 requestId=$requestId deviceId=$deviceId")
            if (!gatt.discoverServices()) {
              Log.w(TAG, "发现服务启动失败 requestId=$requestId deviceId=$deviceId")
            }
          }
          BluetoothProfile.STATE_DISCONNECTED -> {
            gatt.close()
            gattMap.remove(deviceId)
            discoverServicesCallbacks.remove(deviceId)
            authSessions.remove(deviceId)
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

      override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
        val deviceId = device.address
        val requestId = requestIdsByDevice[deviceId] ?: "unknown"
        val callback = discoverServicesCallbacks.remove(deviceId)
        Log.d(
          TAG,
          "蓝牙服务发现完成 requestId=$requestId deviceId=$deviceId status=$status serviceCount=${gatt.services.size}",
        )
        if (status != BluetoothGatt.GATT_SUCCESS) {
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
        maybeStartAuthentication(requestId, deviceId, gatt)
        callback?.invoke(Result.success(mapServices(requestId, deviceId, gatt)))
      }

      @SuppressLint("MissingPermission")
      override fun onCharacteristicChanged(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
      ) {
        val deviceId = device.address
        val requestId = requestIdsByDevice[deviceId]
        val payload = characteristic.value ?: ByteArray(0)
        logBlePayload(
          direction = "NOTIFY",
          requestId = requestId,
          deviceId = deviceId,
          serviceUuid = characteristic.service.uuid.toString(),
          characteristicUuid = characteristic.uuid.toString(),
          payload = payload,
        )
        handleAuthenticationNotification(
          requestId = requestId,
          deviceId = deviceId,
          serviceUuid = characteristic.service.uuid.toString(),
          characteristicUuid = characteristic.uuid.toString(),
          payload = payload,
        )
        logEncryptedPayloadAnalysis(
          requestId = requestId,
          deviceId = deviceId,
          serviceUuid = characteristic.service.uuid.toString(),
          characteristicUuid = characteristic.uuid.toString(),
          payload = payload,
        )
        emitNotification(
          requestId = requestId,
          deviceId = deviceId,
          serviceUuid = characteristic.service.uuid.toString(),
          characteristicUuid = characteristic.uuid.toString(),
          payload = payload,
        )
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
    if (payload.size != 20) {
      return
    }
    val prefix = payload.copyOfRange(0, 4)
    val cipherBytes = payload.copyOfRange(4, payload.size)
    val candidates = DeviceBleProtocolConfig.candidateAesKeys()
    val analyses = candidates.joinToString(separator = " | ") { candidate ->
      describeAesCandidate(candidate, cipherBytes)
    }
    Log.d(
      TAG,
      "蓝牙接收密文分析 requestId=${requestId ?: "unknown"} deviceId=$deviceId service=$serviceUuid characteristic=$characteristicUuid prefixHex=${toHexOrEmpty(prefix)} cipherHex=${toHexOrEmpty(cipherBytes)} analyses=$analyses",
    )
  }

  private fun describeAesCandidate(
    candidate: DeviceBleAesKeyCandidate,
    cipherBytes: ByteArray,
  ): String {
    val pkcs7 = DeviceBleProtocolConfig.tryDecryptAesEcbPkcs7(cipherBytes, candidate.keyBytes)
    val noPadding = DeviceBleProtocolConfig.tryDecryptAesEcbNoPadding(cipherBytes, candidate.keyBytes)
    return buildString {
      append(candidate.label)
      append("{pkcs7=")
      append(pkcs7?.let(::toHexOrEmpty) ?: "fail")
      append(", noPadding=")
      append(noPadding?.let(::toHexOrEmpty) ?: "fail")
      append("}")
    }
  }

  @SuppressLint("MissingPermission")
  private fun maybeStartAuthentication(
    requestId: String,
    deviceId: String,
    gatt: BluetoothGatt,
  ) {
    if (authSessions.containsKey(deviceId)) {
      Log.d(TAG, "跳过自动鉴权 requestId=$requestId deviceId=$deviceId reason=已有鉴权会话")
      return
    }
    val service = gatt.getService(DeviceBleProtocolConfig.communicationServiceUuid)
    if (service == null) {
      Log.d(TAG, "跳过自动鉴权 requestId=$requestId deviceId=$deviceId reason=未发现协议服务")
      return
    }
    val notifyCharacteristic = service.getCharacteristic(DeviceBleProtocolConfig.notifyCharacteristicUuid)
    val writeCharacteristic = service.getCharacteristic(DeviceBleProtocolConfig.writeCharacteristicUuid)
    if (notifyCharacteristic == null || writeCharacteristic == null) {
      Log.w(
        TAG,
        "跳过自动鉴权 requestId=$requestId deviceId=$deviceId reason=协议特征缺失 hasNotify=${notifyCharacteristic != null} hasWrite=${writeCharacteristic != null}",
      )
      return
    }
    val sequence = nextProtocolSequence()
    val payload = DeviceBleProtocolConfig.buildAuthenticationFrame(
      sequence = sequence,
      utcTimestampSeconds = Instant.now().epochSecond,
    )
    val auth = PendingAuthentication(
      requestId = requestId,
      deviceId = deviceId,
      sequence = sequence,
      serviceUuid = service.uuid.toString(),
      notifyCharacteristicUuid = notifyCharacteristic.uuid.toString(),
      writeCharacteristicUuid = writeCharacteristic.uuid.toString(),
      payload = payload,
    )
    authSessions[deviceId] = auth
    Log.d(
      TAG,
      "自动鉴权准备 requestId=$requestId deviceId=$deviceId seq=0x${sequence.toString(16).padStart(4, '0')}",
    )
    val localEnabled = gatt.setCharacteristicNotification(notifyCharacteristic, true)
    if (!localEnabled) {
      Log.w(TAG, "自动鉴权失败 requestId=$requestId deviceId=$deviceId step=开启本地通知失败")
      authSessions.remove(deviceId)
      return
    }
    val descriptor = notifyCharacteristic.getDescriptor(cccdUuid)
    if (descriptor == null) {
      Log.w(TAG, "自动鉴权失败 requestId=$requestId deviceId=$deviceId step=缺少CCCD描述符")
      authSessions.remove(deviceId)
      return
    }
    descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
    Log.d(
      TAG,
      "自动鉴权开启通知 requestId=$requestId deviceId=$deviceId service=${auth.serviceUuid} characteristic=${auth.notifyCharacteristicUuid}",
    )
    if (!gatt.writeDescriptor(descriptor)) {
      Log.w(TAG, "自动鉴权失败 requestId=$requestId deviceId=$deviceId step=写入CCCD失败")
      authSessions.remove(deviceId)
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
        "自动鉴权失败 requestId=${auth.requestId} deviceId=$deviceId step=通知配置回调失败 status=$status",
      )
      authSessions.remove(deviceId)
      return
    }
    val writeCharacteristic = gatt.getService(UUID.fromString(auth.serviceUuid))
      ?.getCharacteristic(UUID.fromString(auth.writeCharacteristicUuid))
    if (writeCharacteristic == null) {
      Log.w(
        TAG,
        "自动鉴权失败 requestId=${auth.requestId} deviceId=$deviceId step=鉴权写特征不存在",
      )
      authSessions.remove(deviceId)
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
        "自动鉴权失败 requestId=${auth.requestId} deviceId=$deviceId step=发送鉴权帧失败",
      )
      authSessions.remove(deviceId)
      return
    }
    Log.d(
      TAG,
      "自动鉴权已发送 requestId=${auth.requestId} deviceId=$deviceId seq=0x${auth.sequence.toString(16).padStart(4, '0')}",
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
    val frame = DeviceBleProtocolConfig.parseFrame(payload)
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
      "自动鉴权结果 requestId=${auth.requestId} callbackRequestId=${requestId ?: "unknown"} deviceId=$deviceId success=$success resultHex=${result?.toString(16)?.padStart(2, '0') ?: ""} bindStateHex=${bindState?.toString(16)?.padStart(2, '0') ?: ""} seq=0x${frame.sequence.toString(16).padStart(4, '0')}",
    )
    if (success) {
      auth.completed = true
    } else {
      authSessions.remove(deviceId)
    }
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
    gatt.services.forEach { service ->
      Log.d(
        TAG,
        "蓝牙服务详情 requestId=$requestId deviceId=$deviceId service=${service.uuid} matchedProtocol=${DeviceBleProtocolConfig.supportsService(service.uuid.toString())} characteristicCount=${service.characteristics.size}",
      )
      service.characteristics.forEach { characteristic ->
        Log.d(
          TAG,
          "蓝牙特征详情 requestId=$requestId deviceId=$deviceId service=${service.uuid} characteristic=${characteristic.uuid} properties=${describeProperties(characteristic.properties)}",
        )
      }
    }
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
    val frame = DeviceBleProtocolConfig.parseFrame(payload) ?: return " protocolFrame=未解析"
    return " protocolFrame=${describeFrame(frame)}"
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

  private fun failPendingOperations(deviceId: String, status: Int) {
    val disconnectError = FlutterError(
      "bluetooth_disconnected",
      "BLE device disconnected during operation.",
      "status=$status,deviceId=$deviceId",
    )
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
  var completed: Boolean = false,
)

private fun Context.bluetoothAdapterOrNull(): BluetoothAdapter? {
  val manager = getSystemService(BluetoothManager::class.java)
  return manager?.adapter
}
