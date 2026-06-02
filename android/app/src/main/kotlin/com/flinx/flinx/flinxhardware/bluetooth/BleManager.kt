package com.flinx.flinx.flinxhardware.bluetooth

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
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
import com.flinx.flinx.flinxhardware.bridge.BleScanFilterDto
import com.flinx.flinx.flinxhardware.bridge.FlutterError

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
    hasScanResult = true
    val device = BleDeviceDto(
      requestId = requestId,
      scanSessionId = requestId,
      id = result.device?.address ?: "",
      name = result.device?.name ?: result.scanRecord?.deviceName,
      rssi = result.rssi.toLong(),
      advertisementServiceUuids = result.scanRecord?.serviceUuids?.map { it.uuid.toString() } ?: emptyList(),
      manufacturerData = flattenManufacturerData(result),
      seenAtMillis = System.currentTimeMillis(),
    )
    Log.d(
      TAG,
      "scan result requestId=$requestId address=${device.id} name=${device.name} rssi=${device.rssi} uuids=${device.advertisementServiceUuids}",
    )
    onDeviceFound?.invoke(device)
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

private fun Context.bluetoothAdapterOrNull(): BluetoothAdapter? {
  val manager = getSystemService(BluetoothManager::class.java)
  return manager?.adapter
}
