import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AndroidBlePermissionGateway {
  const AndroidBlePermissionGateway._();

  static const _channel = MethodChannel('com.flinx/ble_permissions');

  static Future<AndroidBleScanReadiness> requestBleScanReady() async {
    if (kIsWeb || !Platform.isAndroid) {
      return AndroidBleScanReadiness.ready;
    }
    final status = await _channel.invokeMethod<String>('requestBleScanReady');
    return switch (status) {
      'READY' => AndroidBleScanReadiness.ready,
      'PERMISSION_DENIED' => AndroidBleScanReadiness.permissionDenied,
      _ => AndroidBleScanReadiness.cancelled,
    };
  }
}

enum AndroidBleScanReadiness { ready, permissionDenied, cancelled }
