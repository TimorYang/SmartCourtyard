package com.flinx.flinx.flinxhardware.permissions

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.flinx.flinx.flinxhardware.bridge.PermissionSnapshotDto

class PermissionManager(
  private val context: Context,
) {
  /** 读取当前权限快照，供 Flutter 侧展示和前置校验使用。 */
  fun getPermissionSnapshot(): PermissionSnapshotDto {
    val bluetoothGranted = hasBluetoothPermission()
    val cameraGranted = isGranted(Manifest.permission.CAMERA)
    val localNetworkGranted = true
    val notificationGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      isGranted(Manifest.permission.POST_NOTIFICATIONS)
    } else {
      true
    }
    return PermissionSnapshotDto(
      bluetoothGranted = bluetoothGranted,
      cameraGranted = cameraGranted,
      localNetworkGranted = localNetworkGranted,
      notificationGranted = notificationGranted,
    )
  }

  /** 判断蓝牙相关权限是否满足，按 Android 版本区分权限模型。 */
  private fun hasBluetoothPermission(): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      isGranted(Manifest.permission.BLUETOOTH_SCAN) &&
        isGranted(Manifest.permission.BLUETOOTH_CONNECT)
    } else {
      isGranted(Manifest.permission.ACCESS_FINE_LOCATION)
    }
  }

  /** 检查单个权限是否已授予。 */
  private fun isGranted(permission: String): Boolean {
    return ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
  }
}
