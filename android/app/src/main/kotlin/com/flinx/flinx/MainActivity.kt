package com.flinx.flinx

import com.flinx.flinx.flinxhardware.bridge.HardwareHostApi
import com.flinx.flinx.flinxhardware.bridge.HardwareHostApiImpl
import com.flinx.flinx.flinxhardware.permissions.PermissionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val permissionManager = PermissionManager(applicationContext)
    val hardwareHostApi = HardwareHostApiImpl(permissionManager)
    HardwareHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, hardwareHostApi)
  }
}
