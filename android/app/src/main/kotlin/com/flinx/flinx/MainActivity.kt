package com.flinx.flinx

import com.flinx.flinx.flinxhardware.bluetooth.BleManager
import com.flinx.flinx.flinxhardware.bridge.HardwareHostApi
import com.flinx.flinx.flinxhardware.bridge.HardwareFlutterApi
import com.flinx.flinx.flinxhardware.bridge.HardwareHostApiImpl
import com.flinx.flinx.flinxhardware.permissions.PermissionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val messenger = flutterEngine.dartExecutor.binaryMessenger
    val permissionManager = PermissionManager(applicationContext) { this }
    val bleManager = BleManager(applicationContext)
    val hardwareFlutterApi = HardwareFlutterApi(messenger)
    val hardwareHostApi = HardwareHostApiImpl(
      permissionManager = permissionManager,
      bleManager = bleManager,
      hardwareFlutterApi = hardwareFlutterApi,
    )
    HardwareHostApi.setUp(messenger, hardwareHostApi)
  }
}
