package com.feizhou.znty

import android.content.Intent
import android.net.Proxy
import com.feizhou.znty.flinxhardware.bluetooth.BleManager
import com.feizhou.znty.flinxhardware.bridge.HardwareHostApi
import com.feizhou.znty.flinxhardware.bridge.HardwareFlutterApi
import com.feizhou.znty.flinxhardware.bridge.HardwareHostApiImpl
import com.feizhou.znty.flinxhardware.permissions.PermissionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  companion object {
    private const val debugSystemProxyChannel = "com.flinx/debug_system_proxy"
    private const val blePermissionChannel = "com.flinx/ble_permissions"
  }

  private var permissionManager: PermissionManager? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val messenger = flutterEngine.dartExecutor.binaryMessenger
    val permissionManager = PermissionManager(applicationContext) { this }
    this.permissionManager = permissionManager
    val bleManager = BleManager(applicationContext)
    val hardwareFlutterApi = HardwareFlutterApi(messenger)
    val hardwareHostApi = HardwareHostApiImpl(
      permissionManager = permissionManager,
      bleManager = bleManager,
      hardwareFlutterApi = hardwareFlutterApi,
    )
    HardwareHostApi.setUp(messenger, hardwareHostApi)
    MethodChannel(messenger, debugSystemProxyChannel).setMethodCallHandler {
        call, result ->
      if (call.method == "getSystemProxy") {
        result.success(systemProxy())
      } else {
        result.notImplemented()
      }
    }
    MethodChannel(messenger, blePermissionChannel).setMethodCallHandler {
        call, result ->
      if (call.method == "requestBleScanReady") {
        permissionManager.requestBleScanReady { readiness ->
          result.success(readiness.name)
        }
      } else {
        result.notImplemented()
      }
    }
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray,
  ) {
    val handled = permissionManager?.onRequestPermissionsResult(requestCode) == true
    if (!handled) {
      super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    val handled = permissionManager?.onActivityResult(requestCode) == true
    if (!handled) {
      super.onActivityResult(requestCode, resultCode, data)
    }
  }

  private fun systemProxy(): Map<String, Any?> {
    val host = System.getProperty("http.proxyHost")
      ?: System.getProperty("https.proxyHost")
      ?: Proxy.getHost(this)
    val portText = System.getProperty("http.proxyPort")
      ?: System.getProperty("https.proxyPort")
      ?: Proxy.getPort(this).takeIf { it > 0 }?.toString()
    return mapOf("host" to host, "port" to portText?.toIntOrNull())
  }
}
