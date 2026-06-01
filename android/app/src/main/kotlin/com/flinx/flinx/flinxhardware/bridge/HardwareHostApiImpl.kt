package com.flinx.flinx.flinxhardware.bridge

import com.flinx.flinx.flinxhardware.bluetooth.BleManager
import com.flinx.flinx.flinxhardware.permissions.PermissionManager

/** Pigeon HostApi 实现：承接 Flutter 调用并编排权限与 BLE 能力。 */
class HardwareHostApiImpl(
  private val permissionManager: PermissionManager,
  private val bleManager: BleManager,
  private val hardwareFlutterApi: HardwareFlutterApi,
) : HardwareHostApi {

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
    bleManager.startScan(
      requestId = requestId,
      filter = filter,
      onDeviceFound = { device ->
        hardwareFlutterApi.onBleScanResult(device) {}
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

  /** 连接 BLE 设备（待实现）。 */
  override fun connectBleDevice(
    requestId: String,
    deviceId: String,
    callback: (Result<BleConnectionEventDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("connectBleDevice", requestId, deviceId)))
  }

  /** 断开 BLE 设备连接（待实现）。 */
  override fun disconnectBleDevice(
    requestId: String,
    deviceId: String,
    callback: (Result<BleConnectionEventDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("disconnectBleDevice", requestId, deviceId)))
  }

  /** 发现 GATT 服务（待实现）。 */
  override fun discoverServices(
    requestId: String,
    deviceId: String,
    callback: (Result<BleServicesDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("discoverServices", requestId, deviceId)))
  }

  /** 读取特征值（待实现）。 */
  override fun readCharacteristic(
    requestId: String,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    callback: (Result<BleReadResultDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("readCharacteristic", requestId, deviceId)))
  }

  /** 写入特征值（待实现）。 */
  override fun writeCharacteristic(
    requestId: String,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    payload: ByteArray,
    writeType: BleWriteTypeDto,
    callback: (Result<BleWriteResultDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("writeCharacteristic", requestId, deviceId)))
  }

  /** 开关特征通知（待实现）。 */
  override fun setCharacteristicNotify(
    requestId: String,
    deviceId: String,
    serviceUuid: String,
    characteristicUuid: String,
    enabled: Boolean,
    callback: (Result<BleWriteResultDto>) -> Unit,
  ) {
    callback(Result.failure(notImplemented("setCharacteristicNotify", requestId, deviceId)))
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
    hardwareFlutterApi.onNativeError(error) {}
  }
}
