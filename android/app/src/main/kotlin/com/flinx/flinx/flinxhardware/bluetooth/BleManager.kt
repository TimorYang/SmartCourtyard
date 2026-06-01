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
import android.os.ParcelUuid
import com.flinx.flinx.flinxhardware.bridge.BleDeviceDto
import com.flinx.flinx.flinxhardware.bridge.BleScanFilterDto
import com.flinx.flinx.flinxhardware.bridge.FlutterError

/** BLE 管理器：负责扫描生命周期和扫描结果到 DTO 的转换。 */
class BleManager(
  private val context: Context,
) {
  private var scanner: BluetoothLeScanner? = null
  private var activeScanCallback: ScanCallback? = null
  private var activeRequestId: String? = null
  private var onDeviceFound: ((BleDeviceDto) -> Unit)? = null
  private var onError: ((FlutterError) -> Unit)? = null

  /** 启动 BLE 扫描并通过回调输出扫描结果。 */
  @SuppressLint("MissingPermission")
  fun startScan(
    requestId: String,
    filter: BleScanFilterDto,
    onDeviceFound: (BleDeviceDto) -> Unit,
    onError: (FlutterError) -> Unit,
  ) {
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
    this.onDeviceFound = onDeviceFound
    this.onError = onError
    bleScanner.startScan(filters, settings, callback)
  }

  /** 停止当前 BLE 扫描。 */
  @SuppressLint("MissingPermission")
  fun stopScan(requestId: String) {
    val callback = activeScanCallback ?: return
    val currentScanner = scanner ?: return
    currentScanner.stopScan(callback)
    activeScanCallback = null
    scanner = null
    activeRequestId = null
    onDeviceFound = null
    onError = null
  }

  /** 创建 Android 扫描回调，并转换为桥接 DTO。 */
  private fun createScanCallback(requestId: String): ScanCallback {
    return object : ScanCallback() {
      override fun onScanResult(callbackType: Int, result: ScanResult) {
        onDeviceFound?.invoke(
          BleDeviceDto(
            requestId = requestId,
            scanSessionId = requestId,
            id = result.device?.address ?: "",
            name = result.device?.name ?: result.scanRecord?.deviceName,
            rssi = result.rssi.toLong(),
            advertisementServiceUuids = result.scanRecord?.serviceUuids?.map { it.uuid.toString() } ?: emptyList(),
            manufacturerData = flattenManufacturerData(result),
            seenAtMillis = System.currentTimeMillis(),
          ),
        )
      }

      override fun onScanFailed(errorCode: Int) {
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
