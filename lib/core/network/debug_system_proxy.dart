import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reads the Android device's HTTP proxy for local, debug-only inspection.
abstract final class DebugSystemProxy {
  static const MethodChannel _channel = MethodChannel(
    'com.flinx/debug_system_proxy',
  );

  static String? _host;
  static int? _port;

  static bool get isEnabled =>
      kDebugMode &&
      Platform.isAndroid &&
      _host?.isNotEmpty == true &&
      (_port ?? 0) > 0;

  static String get findProxyValue => 'PROXY $_host:$_port';

  /// Android uses its detected system proxy, while iOS keeps the existing
  /// local manual-proxy configuration. The two platform paths are intentionally
  /// independent so Android discovery cannot override iOS debugging settings.
  static String proxyForCurrentPlatform({required String iosProxy}) {
    return selectProxy(
      isAndroid: Platform.isAndroid,
      isIOS: Platform.isIOS,
      androidSystemProxyEnabled: isEnabled,
      androidSystemProxy: findProxyValue,
      iosProxy: iosProxy,
    );
  }

  @visibleForTesting
  static String selectProxy({
    required bool isAndroid,
    required bool isIOS,
    required bool androidSystemProxyEnabled,
    required String androidSystemProxy,
    required String iosProxy,
  }) {
    if (isAndroid) {
      return androidSystemProxyEnabled ? androidSystemProxy.trim() : '';
    }
    if (isIOS) {
      return iosProxy.trim();
    }
    return '';
  }

  static Future<void> initialize() async {
    if (!kDebugMode || !Platform.isAndroid) {
      return;
    }
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getSystemProxy',
      );
      final host = result?['host']?.toString().trim() ?? '';
      final portValue = result?['port'];
      final port = portValue is int
          ? portValue
          : int.tryParse(portValue?.toString() ?? '');
      if (host.isNotEmpty && port != null && port > 0) {
        _host = host;
        _port = port;
        debugPrint('[FLINX][Network] System proxy detected: $host:$port');
      } else {
        _clear();
      }
    } on Object catch (error) {
      _clear();
      debugPrint('[FLINX][Network] System proxy lookup failed: $error');
    }
  }

  static void _clear() {
    _host = null;
    _port = null;
  }
}
