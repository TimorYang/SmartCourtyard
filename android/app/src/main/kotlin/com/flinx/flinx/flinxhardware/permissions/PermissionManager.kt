package com.flinx.flinx.flinxhardware.permissions

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.provider.Settings
import android.net.Uri
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.flinx.flinx.flinxhardware.bridge.PermissionKindDto
import com.flinx.flinx.flinxhardware.bridge.PermissionSnapshotDto
import com.flinx.flinx.flinxhardware.bridge.PermissionStatusDto

/** 权限管理器：负责权限快照读取与运行时权限请求。 */
class PermissionManager(
  private val context: Context,
  private val activityProvider: () -> Activity?,
) {
  /** 读取当前权限快照，供 Flutter 侧展示和前置校验使用。 */
  fun getPermissionSnapshot(): PermissionSnapshotDto {
    val bluetoothStatus = statusFor(PermissionKindDto.BLUETOOTH)
    val cameraStatus = statusFor(PermissionKindDto.CAMERA)
    val locationStatus = statusFor(PermissionKindDto.LOCATION)
    val microphoneStatus = statusFor(PermissionKindDto.MICROPHONE)
    val storageStatus = statusFor(PermissionKindDto.STORAGE)
    val localNetworkGranted = true
    val notificationGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      isGranted(Manifest.permission.POST_NOTIFICATIONS)
    } else {
      true
    }
    return PermissionSnapshotDto(
      bluetoothStatus = bluetoothStatus,
      cameraStatus = cameraStatus,
      locationStatus = locationStatus,
      microphoneStatus = microphoneStatus,
      storageStatus = storageStatus,
      localNetworkGranted = localNetworkGranted,
      notificationGranted = notificationGranted,
    )
  }

  /** 触发权限请求（异步系统弹窗），并立即返回当前快照。 */
  fun requestPermissions(permissions: List<PermissionKindDto>): PermissionSnapshotDto {
    val activity = activityProvider()
    if (activity != null) {
      val missingPermissions = permissions
        .flatMap { mapPermissionKind(it) }
        .distinct()
        .filterNot(::isGranted)
      permissions.forEach(::markRequested)
      if (missingPermissions.isNotEmpty()) {
        ActivityCompat.requestPermissions(
          activity,
          missingPermissions.toTypedArray(),
          REQUEST_CODE,
        )
      }
    }
    return getPermissionSnapshot()
  }

  fun openAppSettings() {
    val intent = android.content.Intent(
      Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
      Uri.fromParts("package", context.packageName, null),
    ).addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
    context.startActivity(intent)
  }

  /** 判断当前系统是否满足 BLE 扫描所需前置条件。 */
  fun ensureBleScanPreconditions() {
    if (!hasBluetoothPermission()) {
      throw com.flinx.flinx.flinxhardware.bridge.FlutterError(
        "permission_denied",
        "Bluetooth scan permission is not granted.",
      )
    }
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S && !isLocationServiceEnabled()) {
      throw com.flinx.flinx.flinxhardware.bridge.FlutterError(
        "location_services_disabled",
        "Location services must be enabled for BLE scanning on this Android version.",
      )
    }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !isLocationServiceEnabled()) {
      throw com.flinx.flinx.flinxhardware.bridge.FlutterError(
        "location_services_disabled",
        "Location services must be enabled for reliable BLE scanning on this device.",
      )
    }
  }

  /** 判断当前系统是否满足 BLE 连接所需前置条件。 */
  fun ensureBleConnectPreconditions() {
    if (!hasBluetoothPermission()) {
      throw com.flinx.flinx.flinxhardware.bridge.FlutterError(
        "permission_denied",
        "Bluetooth connection permission is not granted.",
      )
    }
  }

  /** 判断蓝牙相关权限是否满足，按 Android 版本区分权限模型。 */
  private fun hasBluetoothPermission(): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      isGranted(Manifest.permission.BLUETOOTH_SCAN) &&
        isGranted(Manifest.permission.BLUETOOTH_CONNECT) &&
        isGranted(Manifest.permission.ACCESS_FINE_LOCATION)
    } else {
      isGranted(Manifest.permission.ACCESS_FINE_LOCATION)
    }
  }

  private fun statusFor(kind: PermissionKindDto): PermissionStatusDto {
    val permissions = mapPermissionKind(kind)
    if (permissions.isEmpty()) return PermissionStatusDto.GRANTED
    if (permissions.all(::isGranted)) return PermissionStatusDto.GRANTED
    val activity = activityProvider()
    val wasRequested = context
      .getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
      .getBoolean("requested_${kind.name}", false)
    val canRequestAgain = activity != null && permissions.any {
      ActivityCompat.shouldShowRequestPermissionRationale(activity, it)
    }
    return if (wasRequested && !canRequestAgain) {
      PermissionStatusDto.BLOCKED
    } else {
      PermissionStatusDto.DENIED
    }
  }

  private fun markRequested(kind: PermissionKindDto) {
    context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
      .edit()
      .putBoolean("requested_${kind.name}", true)
      .apply()
  }

  /** 检查单个权限是否已授予。 */
  private fun isGranted(permission: String): Boolean {
    return ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
  }

  /** 检查系统定位开关是否开启，Android 11 及以下 BLE 扫描依赖它。 */
  private fun isLocationServiceEnabled(): Boolean {
    val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
    return locationManager?.isProviderEnabled(LocationManager.GPS_PROVIDER) == true ||
      locationManager?.isProviderEnabled(LocationManager.NETWORK_PROVIDER) == true
  }

  /** 将 Pigeon 权限类型映射为 Android 运行时权限列表。 */
  private fun mapPermissionKind(kind: PermissionKindDto): List<String> {
    return when (kind) {
      PermissionKindDto.BLUETOOTH -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
          listOf(
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.ACCESS_FINE_LOCATION,
          )
        } else {
          listOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }
      }
      PermissionKindDto.CAMERA -> listOf(Manifest.permission.CAMERA)
      PermissionKindDto.LOCATION -> listOf(Manifest.permission.ACCESS_FINE_LOCATION)
      PermissionKindDto.MICROPHONE -> listOf(Manifest.permission.RECORD_AUDIO)
      PermissionKindDto.STORAGE -> when {
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU ->
          listOf(Manifest.permission.READ_MEDIA_IMAGES)
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.R ->
          listOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        else -> listOf(
          Manifest.permission.READ_EXTERNAL_STORAGE,
          Manifest.permission.WRITE_EXTERNAL_STORAGE,
        )
      }
      PermissionKindDto.LOCAL_NETWORK -> emptyList()
      PermissionKindDto.NOTIFICATION -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
          listOf(Manifest.permission.POST_NOTIFICATIONS)
        } else {
          emptyList()
        }
      }
    }
  }

  private companion object {
    const val REQUEST_CODE = 9001
    const val PREFERENCES = "flinx_permission_requests"
  }
}
