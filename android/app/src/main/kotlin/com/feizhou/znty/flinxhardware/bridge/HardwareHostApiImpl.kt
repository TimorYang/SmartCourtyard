package com.feizhou.znty.flinxhardware.bridge

import android.os.Handler
import android.os.Looper
import com.feizhou.znty.flinxhardware.bluetooth.BleManager
import com.feizhou.znty.flinxhardware.permissions.PermissionManager
import com.feizhou.znty.flinxhardware.protocol.DeviceBleProtocolConfig
import com.feizhou.znty.flinxhardware.protocol.DeviceBleFrame
import com.feizhou.znty.flinxhardware.protocol.DeviceRemotePairingResult
import java.nio.ByteBuffer
import java.nio.ByteOrder

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
    bleManager.onProtocolFrame = ::handleProtocolFrame
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
    executeProtocol(requestId, deviceId, DeviceBleProtocolConfig.commandQueryAttributes, DeviceBleProtocolConfig.commandAttributeReport, callback = callback) { frame ->
      attributesSnapshot(requestId, deviceId, frame, DeviceAttributeReportOriginDto.QUERY_RESULT).also { snapshot ->
        runOnMainThread { hardwareFlutterApi.onDeviceAttributesChanged(snapshot) {} }
      }
    }
  }

  override fun setDeviceAttributes(
    requestId: String,
    deviceId: String,
    attributes: List<DeviceAttributeDto>,
    callback: (Result<DeviceAttributeWriteResultDto>) -> Unit,
  ) {
    val payload = runCatching { DeviceAttributeProtocol.encode(attributes) }.getOrElse { callback(Result.failure(it)); return }
    executeProtocol(requestId, deviceId, DeviceBleProtocolConfig.commandSetAttributes, data = payload, callback = callback) { frame ->
      val result = frame.data.firstOrNull()?.toInt()?.and(0xFF)
        ?: throw FlutterError("invalid_attribute_write_response", "Attribute write response is empty.")
      DeviceAttributeWriteResultDto(requestId, deviceId, result == 0x01, frame.sequence.toLong(), frame.data.reasonCode())
    }
  }

  override fun setDoorOpenReminder(
    requestId: String,
    deviceId: String,
    value: Long,
    callback: (Result<CommandResultDto>) -> Unit,
  ) {
    if (!DeviceBleProtocolConfig.isValidDoorOpenReminderValue(value)) {
      callback(
        Result.failure(
          FlutterError(
            "invalid_door_open_reminder_value",
            "Door open reminder value is not supported.",
          ),
        ),
      )
      return
    }
    val valueByte = value.toInt()
    executeProtocol(
      requestId = requestId,
      deviceId = deviceId,
      command = DeviceBleProtocolConfig.commandDoorOpenReminder,
      data = byteArrayOf(valueByte.toByte()),
      operation = "Door Open Reminder",
      callback = callback,
    ) { frame ->
      val result = DeviceBleProtocolConfig.doorOpenReminderResponseCode(frame.data)
        ?: throw FlutterError(
          "invalid_door_open_reminder_response",
          "Door open reminder response must contain one result byte.",
        )
      CommandResultDto(
        requestId = requestId,
        deviceId = deviceId,
        accepted = result == 0x01,
        nativeCode = "command=0x0E09,data=0x%02X,result=0x%02X".format(valueByte, result),
        domainCode = if (result == 0x01) null else "door_open_reminder_rejected",
      )
    }
  }

  override fun pairRemote(
    requestId: String,
    deviceId: String,
    action: RemotePairingActionDto,
    callback: (Result<RemotePairingResultDto>) -> Unit,
  ) {
    val control = if (action == RemotePairingActionDto.START) {
      DeviceBleProtocolConfig.controlRemotePairingStart
    } else {
      DeviceBleProtocolConfig.controlRemotePairingCancel
    }
    if (action == RemotePairingActionDto.CANCEL) {
      bleManager.cancelProtocolCommand(deviceId, "remote_pairing_cancelled")
    }
    executePairing(
      requestId = requestId,
      deviceId = deviceId,
      command = DeviceBleProtocolConfig.commandControlDoor,
      responseCommand = DeviceBleProtocolConfig.commandRemotePairingResponse,
      control = control,
      timeout = DeviceBleProtocolConfig.remotePairingResponseTimeoutMillis,
      operation = "Remote Pairing",
      callback = callback,
    ) { result, _ ->
      val status = remotePairingStatus(result)
      val reason = if (status == RemotePairingStatusDto.SUCCESS) 0L else result.toLong()
      RemotePairingResultDto(
        requestId,
        deviceId,
        status,
        reason,
        "command=0x0005,responseCommand=0x0104,control=0x%04X,result=0x%02X".format(control, result),
        if (status == RemotePairingStatusDto.SUCCESS) null else "pairing_failed",
      )
    }
  }

  override fun pairSafetyAccessory(
    requestId: String,
    deviceId: String,
    action: SafetyAccessoryPairingActionDto,
    callback: (Result<SafetyAccessoryPairingResultDto>) -> Unit,
  ) {
    val control = if (action == SafetyAccessoryPairingActionDto.START) {
      DeviceBleProtocolConfig.controlSafetyAccessoryPairingStart
    } else {
      DeviceBleProtocolConfig.controlSafetyAccessoryPairingCancel
    }
    if (action == SafetyAccessoryPairingActionDto.CANCEL) {
      bleManager.cancelProtocolCommand(deviceId, "safety_accessory_pairing_cancelled")
    }
    executePairing(
      requestId = requestId,
      deviceId = deviceId,
      command = DeviceBleProtocolConfig.commandSafetyAccessoryPairing,
      control = control,
      timeout = 30_000L,
      operation = "Safety Accessory Pairing",
      responseParser = { frame ->
        val response = DeviceBleProtocolConfig.parseSafetyAccessoryPairingFinalReport(
          frameType = frame.frameType,
          command = frame.command,
          data = frame.data,
        )
          ?: throw FlutterError(
            "invalid_safety_accessory_pairing_response",
            "Safety accessory pairing result report is invalid.",
          )
        response.resultCode to response.reasonCode
      },
      callback = callback,
    ) { result, reason ->
      SafetyAccessoryPairingResultDto(requestId, deviceId, safetyPairingStatus(result), reason, "result=0x%02X".format(result), if (result == 1) null else "pairing_failed")
    }
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
    executeProtocol(requestId, deviceId, DeviceBleProtocolConfig.commandRemoteQuery, callback = callback) { frame -> remoteList(requestId, deviceId, frame.data) }
  }

  override fun deleteRemote(
    requestId: String,
    deviceId: String,
    serialNumber: Long?,
    callback: (Result<RemoteOperationResultDto>) -> Unit,
  ) {
    val payload = byteArrayOf(if (serialNumber == null) 0xFF.toByte() else 0x01) + intBytes((serialNumber ?: 0).toInt())
    executeProtocol(requestId, deviceId, DeviceBleProtocolConfig.commandRemoteDelete, data = payload, callback = callback) { frame -> remoteOperation(requestId, deviceId, frame.data) }
  }

  override fun renameRemote(
    requestId: String,
    deviceId: String,
    serialNumber: Long,
    name: String,
    callback: (Result<RemoteOperationResultDto>) -> Unit,
  ) {
    val nameBytes = name.toByteArray(Charsets.UTF_8).copyOf(8)
    executeProtocol(requestId, deviceId, DeviceBleProtocolConfig.commandRemoteRename, data = nameBytes + intBytes(serialNumber.toInt()), callback = callback) { frame -> remoteOperation(requestId, deviceId, frame.data) }
  }

  private fun <T> executeProtocol(
    requestId: String, deviceId: String, command: Int, responseCommand: Int = command,
    data: ByteArray = ByteArray(0), timeoutMillis: Long = 15_000L,
    operation: String? = null, control: Int? = null,
    callback: (Result<T>) -> Unit, transform: (com.feizhou.znty.flinxhardware.protocol.DeviceBleFrame) -> T,
  ) {
    permissionManager.ensureBleConnectPreconditions()
    bleManager.executeProtocolCommand(
      requestId = requestId,
      deviceId = deviceId,
      command = command,
      responseCommand = responseCommand,
      data = data,
      timeoutMillis = timeoutMillis,
      operation = operation,
      control = control,
      callback = { result ->
      callback(result.mapCatching(transform))
      },
    )
  }

  private fun <T> executePairing(
    requestId: String, deviceId: String, command: Int,
    responseCommand: Int = command, control: Int, timeout: Long,
    operation: String,
    responseParser: ((DeviceBleFrame) -> Pair<Int, Long>)? = null,
    callback: (Result<T>) -> Unit, transform: (Int, Long) -> T,
  ) = executeProtocol(
    requestId = requestId,
    deviceId = deviceId,
    command = command,
    responseCommand = responseCommand,
    data = shortBytes(control),
    timeoutMillis = timeout,
    operation = operation,
    control = control,
    callback = callback,
  ) { frame ->
    val parsed = responseParser?.invoke(frame) ?: run {
      val result = frame.data.firstOrNull()?.toInt()?.and(0xFF)
        ?: throw FlutterError("invalid_pairing_response", "Pairing response is empty.")
      result to frame.data.reasonCode()
    }
    transform(parsed.first, parsed.second)
  }

  private fun handleProtocolFrame(deviceId: String, frame: com.feizhou.znty.flinxhardware.protocol.DeviceBleFrame) {
    if (frame.command != DeviceBleProtocolConfig.commandAttributeReport) return
    runCatching { attributesSnapshot(null, deviceId, frame, DeviceAttributeReportOriginDto.ACTIVE_REPORT) }
      .onSuccess { snapshot -> runOnMainThread { hardwareFlutterApi.onDeviceAttributesChanged(snapshot) {} } }
  }

  private fun attributesSnapshot(requestId: String?, deviceId: String, frame: com.feizhou.znty.flinxhardware.protocol.DeviceBleFrame, origin: DeviceAttributeReportOriginDto): DeviceAttributeSnapshotDto =
    DeviceAttributeSnapshotDto(requestId, deviceId, frame.sequence.toLong(), System.currentTimeMillis(), origin, DeviceAttributeProtocol.parse(frame.data))

  private fun remoteList(requestId: String, deviceId: String, data: ByteArray): RemoteControlListResultDto {
    if (data.size < 4) throw FlutterError("invalid_remote_query_response", "Remote list response is incomplete.")
    val remotes = mutableListOf<RemoteControlDto>(); var offset = 4
    while (offset + 12 <= data.size) { val name = data.copyOfRange(offset, offset + 8).toString(Charsets.UTF_8).trimEnd('\u0000'); val serial = ByteBuffer.wrap(data, offset + 8, 4).order(ByteOrder.BIG_ENDIAN).int.toLong() and 0xffffffffL; remotes += RemoteControlDto(name, serial); offset += 12 }
    return RemoteControlListResultDto(requestId, deviceId, (data[0].toInt() and 255).toLong(), (data[1].toInt() and 255).toLong(), (data[2].toInt() and 255).toLong(), data[3].toInt() != 0, remotes)
  }

  private fun remoteOperation(requestId: String, deviceId: String, data: ByteArray): RemoteOperationResultDto { val result = data.firstOrNull()?.toInt()?.and(255) ?: throw FlutterError("invalid_remote_operation_response", "Remote operation response is empty."); return RemoteOperationResultDto(requestId, deviceId, if (result == 1) RemoteOperationStatusDto.SUCCESS else if (result == 255) RemoteOperationStatusDto.FAILURE else RemoteOperationStatusDto.UNKNOWN, data.reasonCode(), "result=0x%02X".format(result), if (result == 1) null else "remote_operation_failed") }
  private fun remotePairingStatus(result: Int) = when (
    DeviceBleProtocolConfig.remotePairingResult(result)
  ) {
    DeviceRemotePairingResult.SUCCESS -> RemotePairingStatusDto.SUCCESS
    DeviceRemotePairingResult.FAILURE -> RemotePairingStatusDto.FAILURE
    DeviceRemotePairingResult.UNKNOWN -> RemotePairingStatusDto.UNKNOWN
  }
  private fun safetyPairingStatus(result: Int) = when (result) { 1 -> SafetyAccessoryPairingStatusDto.SUCCESS; 2 -> SafetyAccessoryPairingStatusDto.FAILURE; 3 -> SafetyAccessoryPairingStatusDto.TIMEOUT; else -> SafetyAccessoryPairingStatusDto.UNKNOWN }
  private fun shortBytes(value: Int) = byteArrayOf((value shr 8).toByte(), value.toByte())
  private fun intBytes(value: Int) = ByteBuffer.allocate(4).order(ByteOrder.BIG_ENDIAN).putInt(value).array()
  private fun ByteArray.reasonCode(): Long = if (size >= 5) ByteBuffer.wrap(this, 1, 4).order(ByteOrder.BIG_ENDIAN).int.toLong() and 0xffffffffL else 0L

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

internal object DeviceAttributeProtocol {
  private const val nullTerminatedStringAttribute = 0x2700

  private val valueWidths = mapOf(
    0x2702 to 2, 0x2703 to 2,
    0x2709 to 1, 0x2710 to 1, 0x2711 to 1, 0x2712 to 1,
    0x2713 to 1, 0x2714 to 1, 0x2715 to 1, 0x2716 to 2,
    0x2717 to 1, 0x2718 to 1, 0x2719 to 1, 0x271A to 2,
    0x271B to 1, 0x271C to 1, 0x271D to 1, 0x271F to 1,
    0x2720 to 1, 0x2721 to 1, 0x2722 to 1, 0x2723 to 1,
    0x2725 to 2, 0x2726 to 1, 0x2727 to 1, 0x2728 to 1,
    0x2729 to 1, 0x272B to 1, 0x2735 to 1, 0x273B to 1,
    0x273C to 1, 0x273D to 1,
  )

  private val writableAttributes = setOf(
    0x2711, 0x2712, 0x2713, 0x2714, 0x2726, 0x2727,
  )

  fun parse(data: ByteArray): List<DeviceAttributeDto> {
    val attributes = mutableListOf<DeviceAttributeDto>()
    var offset = 0
    while (offset + 2 <= data.size) {
      val id = ((data[offset].toInt() and 0xFF) shl 8) or
        (data[offset + 1].toInt() and 0xFF)
      offset += 2
      val width = if (id == nullTerminatedStringAttribute) {
        val terminator = data.indices.firstOrNull {
          it >= offset && data[it] == 0.toByte()
        } ?: throw FlutterError(
          "invalid_attribute_payload",
          "Unterminated string attribute.",
        )
        terminator - offset + 1
      } else {
        valueWidths[id] ?: throw FlutterError(
          "unsupported_attribute_schema",
          "Unsupported attribute 0x${id.toString(16)}",
        )
      }
      if (offset + width > data.size) {
        throw FlutterError(
          "invalid_attribute_payload",
          "Truncated attribute payload.",
        )
      }
      attributes += DeviceAttributeDto(
        id.toLong(),
        data.copyOfRange(offset, offset + width),
      )
      offset += width
    }
    return attributes
  }

  fun encode(attributes: List<DeviceAttributeDto>): ByteArray {
    require(attributes.isNotEmpty()) { "At least one attribute is required." }
    return attributes.fold(ByteArray(0)) { bytes, attribute ->
      val id = attribute.id.toInt()
      require(id in writableAttributes) { "Unsupported attribute write." }
      val expectedWidth = valueWidths.getValue(id)
      require(attribute.value.size == expectedWidth) {
        "Attribute 0x${id.toString(16)} requires $expectedWidth value bytes."
      }
      bytes + byteArrayOf((id shr 8).toByte(), id.toByte()) + attribute.value
    }
  }
}
