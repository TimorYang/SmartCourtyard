package com.flinx.flinx.flinxhardware.bridge

import android.os.Handler
import android.os.Looper
import com.flinx.flinx.flinxhardware.bluetooth.BleManager
import com.flinx.flinx.flinxhardware.permissions.PermissionManager
import com.flinx.flinx.flinxhardware.protocol.DeviceBleProtocolConfig

/** Pigeon HostApi 实现：承接 Flutter 调用并编排权限与 BLE 能力。 */
class HardwareHostApiImpl(
  private val permissionManager: PermissionManager,
  private val bleManager: BleManager,
  private val hardwareFlutterApi: HardwareFlutterApi,
) : HardwareHostApi {
  private val mainHandler = Handler(Looper.getMainLooper())

  init {
    bleManager.onNotification = ::emitNotification
  }

  /** 获取当前权限状态快照。 */
  override fun getPermissionSnapshot(): PermissionSnapshotDto {
    return permissionManager.getPermissionSnapshot()
  }

  /** 请求权限（当前为骨架实现：直接返回现有快照）。 */
  override fun requestPermissions(permissions: List<PermissionKindDto>): PermissionSnapshotDto {
    return permissionManager.requestPermissions(permissions)
  }

  /** 启动 BLE 扫描并通过 FlutterApi 回推扫描结果。 */
  override fun startBleScan(requestId: String, filter: BleScanFilterDto) {
    permissionManager.ensureBleScanPreconditions()
    bleManager.startScan(
      requestId = requestId,
      filter = filter,
      onDeviceFound = { device ->
        runOnMainThread {
          hardwareFlutterApi.onBleScanResult(device) {}
        }
      },
      onError = { error ->
        emitNativeError(
          code = error.code,
          message = error.message,
          requestId = requestId,
          retryable = true,
        )
      },
    )
  }

  /** 停止 BLE 扫描。 */
  override fun stopBleScan(requestId: String) {
    bleManager.stopScan(requestId)
  }

  /** 连接 BLE 设备。 */
  override fun connectBleDevice(
    requestId: String,
    deviceId: String,
    callback: (Result<BleConnectionEventDto>) -> Unit,
  ) {
    permissionManager.ensureBleConnectPreconditions()
    bleManager.connectDevice(
      requestId = requestId,
      deviceId = deviceId,
      onConnectionChanged = ::emitConnectionChanged,
      callback = callback,
    )
  }

  override fun authenticateBleDevice(
    requestId: String,
    deviceId: String,
    token: String,
    callback: (Result<BleAuthenticationResultDto>) -> Unit,
  ) {
    permissionManager.ensureBleConnectPreconditions()
    bleManager.authenticateDevice(
      requestId = requestId,
      deviceId = deviceId,
      token = token,
      callback = callback,
    )
  }

  override fun scanWifiNetworks(
    requestId: String,
    deviceId: String,
    callback: (Result<WifiScanResultDto>) -> Unit,
  ) {
    permissionManager.ensureBleConnectPreconditions()
    bleManager.scanWifiNetworks(
      requestId = requestId,
      deviceId = deviceId,
      callback = callback,
    )
  }

  override fun configureWifi(
    requestId: String,
    deviceId: String,
    ssid: String,
    password: String,
    callback: (Result<WifiProvisionResultDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("configureWifi", requestId, deviceId)))
  }

  /** 断开 BLE 设备连接。 */
  override fun disconnectBleDevice(
    requestId: String,
    deviceId: String,
    callback: (Result<BleConnectionEventDto>) -> Unit,
  ) {
    permissionManager.ensureBleConnectPreconditions()
    bleManager.disconnectDevice(
      requestId = requestId,
      deviceId = deviceId,
      onConnectionChanged = ::emitConnectionChanged,
      callback = callback,
    )
  }

  /** 发现 GATT 服务。 */
  override fun discoverServices(
    requestId: String,
    deviceId: String,
    callback: (Result<BleServicesDto>) -> Unit,
  ) {
    permissionManager.ensureBleConnectPreconditions()
    bleManager.discoverServices(
      requestId = requestId,
      deviceId = deviceId,
      callback = { result ->
        result.onSuccess { services ->
          val hasProtocolService = services.services.any {
            it.serviceUuid.equals(
              DeviceBleProtocolConfig.communicationServiceUuid.toString(),
              ignoreCase = true,
            )
          }
          emitNativeError(
            code = "service_discovery_summary",
            message = "discoverServices matchedProtocolService=$hasProtocolService count=${services.services.size}",
            requestId = requestId,
            deviceId = deviceId,
            retryable = false,
          )
        }
        callback(result)
      },
    )
  }

  /** 读取特征值。 */
  override fun readCharacteristic(
    requestId: String,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    callback: (Result<BleReadResultDto>) -> Unit,
  ) {
    permissionManager.ensureBleConnectPreconditions()
    bleManager.readCharacteristic(
      requestId = requestId,
      deviceId = deviceId,
      serviceUuid = serviceUuid,
      characteristicUuid = characteristicUuid,
      callback = callback,
    )
  }

  /** 写入特征值。 */
  override fun writeCharacteristic(
    requestId: String,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    payload: ByteArray,
    writeType: BleWriteTypeDto,
    callback: (Result<BleWriteResultDto>) -> Unit,
  ) {
    permissionManager.ensureBleConnectPreconditions()
    bleManager.writeCharacteristic(
      requestId = requestId,
      deviceId = deviceId,
      serviceUuid = serviceUuid,
      characteristicUuid = characteristicUuid,
      payload = payload,
      writeType = writeType,
      callback = callback,
    )
  }

  /** 开关特征通知。 */
  override fun setCharacteristicNotify(
    requestId: String,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    enabled: Boolean,
    callback: (Result<BleWriteResultDto>) -> Unit,
  ) {
    permissionManager.ensureBleConnectPreconditions()
    bleManager.setCharacteristicNotify(
      requestId = requestId,
      deviceId = deviceId,
      serviceUuid = serviceUuid,
      characteristicUuid = characteristicUuid,
      enabled = enabled,
      callback = callback,
    )
  }

  /** 发送门控命令（待实现）。 */
  override fun sendDoorCommand(
    requestId: String,
    deviceId: String,
    command: DoorCommandDto,
  ): CommandResultDto {
    throw notImplemented("sendDoorCommand", requestId, deviceId)
  }

  /** 生成统一的“未实现”错误，附带方法与请求上下文信息。 */
  private fun notImplemented(method: String, requestId: String, deviceId: String? = null): FlutterError {
    val details = buildString {
      append("method=")
      append(method)
      append(", requestId=")
      append(requestId)
      if (deviceId != null) {
        append(", deviceId=")
        append(deviceId)
      }
    }
    return FlutterError(
      code = "not_implemented",
      message = "Android BLE module is not implemented yet.",
      details = details,
    )
  }

  /** 发送统一 NativeError 事件给 Flutter，便于页面层做错误状态映射。 */
  private fun emitNativeError(
    code: String,
    message: String?,
    requestId: String? = null,
    deviceId: String? = null,
    retryable: Boolean = false,
  ) {
    val error = NativeErrorDto(
      code = code,
      domainCode = "Unknown",
      message = message,
      requestId = requestId,
      deviceId = deviceId,
      retryable = retryable,
      timestampMillis = System.currentTimeMillis(),
    )
    runOnMainThread {
      hardwareFlutterApi.onNativeError(error) {}
    }
  }

  /** 发送 BLE 连接状态变化事件给 Flutter。 */
  private fun emitConnectionChanged(event: BleConnectionEventDto) {
    runOnMainThread {
      hardwareFlutterApi.onBleConnectionChanged(event) {}
    }
  }

  /** 发送 BLE 特征通知给 Flutter。 */
  private fun emitNotification(notification: BleNotificationDto) {
    runOnMainThread {
      hardwareFlutterApi.onBleNotification(notification) {}
    }
  }

  /** 确保 Flutter 通道消息总是在主线程发送。 */
  private fun runOnMainThread(action: () -> Unit) {
    if (Looper.myLooper() == Looper.getMainLooper()) {
      action()
    } else {
      mainHandler.post(action)
    }
  }
}
