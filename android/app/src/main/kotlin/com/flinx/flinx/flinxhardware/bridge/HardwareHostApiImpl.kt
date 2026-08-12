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
  override fun configureHardwareLogging(
    flutterConsoleEnabled: Boolean,
    nativeConsoleEnabled: Boolean,
  ) {
    bleManager.configureLogging(
      flutterConsoleEnabled = flutterConsoleEnabled,
      nativeConsoleEnabled = nativeConsoleEnabled,
    )
  }

  private val mainHandler = Handler(Looper.getMainLooper())

  init {
    bleManager.onNotification = ::emitNotification
    bleManager.onDiagnosticEvent = ::emitDiagnosticEvent
  }

  private fun emitDiagnosticEvent(event: BleDiagnosticEventDto) {
    runOnMainThread {
      hardwareFlutterApi.onBleDiagnosticEvent(event) {}
    }
  }

  /** 获取当前权限状态快照。 */
  override fun getPermissionSnapshot(requestId: String): PermissionSnapshotDto {
    return permissionManager.getPermissionSnapshot()
  }

  /** 请求权限（当前为骨架实现：直接返回现有快照）。 */
  override fun requestPermissions(
    requestId: String,
    permissions: List<PermissionKindDto>,
  ): PermissionSnapshotDto {
    return permissionManager.requestPermissions(permissions)
  }

  override fun openAppSettings(requestId: String) {
    permissionManager.openAppSettings()
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

  override fun getConnectedBleDevices(
    requestId: String,
    callback: (Result<List<ConnectedBleDeviceDto>>) -> Unit,
  ) {
    callback(Result.success(bleManager.connectedManagedDevices()))
  }

  override fun disconnectAllManagedBleDevices(
    requestId: String,
    callback: (Result<List<BleConnectionEventDto>>) -> Unit,
  ) {
    bleManager.disconnectAllManagedDevices(
      requestId = requestId,
      onConnectionChanged = ::emitConnectionChanged,
      callback = callback,
    )
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
    aesKey: String,
    aesKeyVersion: String,
    callback: (Result<BleAuthenticationResultDto>) -> Unit,
  ) {
    permissionManager.ensureBleConnectPreconditions()
    bleManager.authenticateDevice(
      requestId = requestId,
      deviceId = deviceId,
      token = token,
      aesKey = aesKey,
      aesKeyVersion = aesKeyVersion,
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
    permissionManager.ensureBleConnectPreconditions()
    bleManager.configureWifi(
      requestId = requestId,
      deviceId = deviceId,
      ssid = ssid,
      password = password,
      callback = callback,
    )
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

  /** 发送门控命令。 */
  override fun sendDoorCommand(
    requestId: String,
    deviceId: String,
    command: DoorCommandDto,
    callback: (Result<CommandResultDto>) -> Unit,
  ) {
    try {
      permissionManager.ensureBleConnectPreconditions()
      val control = when (command) {
        DoorCommandDto.OPEN -> DeviceBleProtocolConfig.controlOpenDoor
        DoorCommandDto.CLOSE -> DeviceBleProtocolConfig.controlCloseDoor
        DoorCommandDto.STOP -> DeviceBleProtocolConfig.controlStopDoor
        DoorCommandDto.PARTIAL_OPEN -> DeviceBleProtocolConfig.controlPartialOpenDoor
        DoorCommandDto.LIGHT_ON -> DeviceBleProtocolConfig.controlLightOn
        DoorCommandDto.LIGHT_OFF -> DeviceBleProtocolConfig.controlLightOff
        DoorCommandDto.PB -> DeviceBleProtocolConfig.controlPb
      }
      callback(
        Result.success(
          bleManager.sendDoorCommand(
            requestId = requestId,
            deviceId = deviceId,
            control = control,
          ),
        ),
      )
    } catch (error: Throwable) {
      callback(Result.failure(error))
    }
  }

  override fun queryDeviceAttributes(
    requestId: String,
    deviceId: String,
    callback: (Result<DeviceAttributeSnapshotDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("queryDeviceAttributes", requestId, deviceId)))
  }

  override fun setDeviceAttributes(
    requestId: String,
    deviceId: String,
    attributes: List<DeviceAttributeDto>,
    callback: (Result<DeviceAttributeWriteResultDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("setDeviceAttributes", requestId, deviceId)))
  }

  override fun pairRemote(
    requestId: String,
    deviceId: String,
    action: RemotePairingActionDto,
    callback: (Result<RemotePairingResultDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("pairRemote", requestId, deviceId)))
  }

  override fun pairSafetyAccessory(
    requestId: String,
    deviceId: String,
    action: SafetyAccessoryPairingActionDto,
    callback: (Result<SafetyAccessoryPairingResultDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("pairSafetyAccessory", requestId, deviceId)))
  }

  override fun querySafetyAccessories(
    requestId: String,
    deviceId: String,
    callback: (Result<SafetyAccessoryListResultDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("querySafetyAccessories", requestId, deviceId)))
  }

  override fun deleteSafetyAccessory(
    requestId: String,
    deviceId: String,
    serialNumber: Long,
    callback: (Result<SafetyAccessoryDeleteResultDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("deleteSafetyAccessory", requestId, deviceId)))
  }

  override fun queryRemotes(
    requestId: String,
    deviceId: String,
    callback: (Result<RemoteControlListResultDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("queryRemotes", requestId, deviceId)))
  }

  override fun deleteRemote(
    requestId: String,
    deviceId: String,
    serialNumber: Long?,
    callback: (Result<RemoteOperationResultDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("deleteRemote", requestId, deviceId)))
  }

  override fun renameRemote(
    requestId: String,
    deviceId: String,
    serialNumber: Long,
    name: String,
    callback: (Result<RemoteOperationResultDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("renameRemote", requestId, deviceId)))
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
