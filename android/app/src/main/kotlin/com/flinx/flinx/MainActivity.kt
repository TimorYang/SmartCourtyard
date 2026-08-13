package com.flinx.flinx

import android.net.Proxy
import com.flinx.flinx.flinxhardware.bluetooth.BleManager
import com.flinx.flinx.flinxhardware.bridge.HardwareHostApi
import com.flinx.flinx.flinxhardware.bridge.HardwareFlutterApi
import com.flinx.flinx.flinxhardware.bridge.HardwareHostApiImpl
import com.flinx.flinx.flinxhardware.permissions.PermissionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  companion object {
    private const val debugSystemProxyChannel = "com.flinx/debug_system_proxy"
  }

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
    MethodChannel(messenger, debugSystemProxyChannel).setMethodCallHandler {
        call, result ->
      if (call.method == "getSystemProxy") {
        result.success(systemProxy())
      } else {
        result.notImplemented()
      }
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
