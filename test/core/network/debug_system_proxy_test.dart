import 'package:flinx/core/network/debug_system_proxy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DebugSystemProxy.selectProxy', () {
    test('uses the detected system proxy on Android', () {
      final proxy = DebugSystemProxy.selectProxy(
        isAndroid: true,
        isIOS: false,
        androidSystemProxyEnabled: true,
        androidSystemProxy: 'PROXY 192.168.1.10:8888',
        iosProxy: 'PROXY 192.168.1.20:9090',
      );

      expect(proxy, 'PROXY 192.168.1.10:8888');
    });

    test('does not fall back to the iOS setting on Android', () {
      final proxy = DebugSystemProxy.selectProxy(
        isAndroid: true,
        isIOS: false,
        androidSystemProxyEnabled: false,
        androidSystemProxy: '',
        iosProxy: 'PROXY 192.168.1.20:9090',
      );

      expect(proxy, isEmpty);
    });

    test('keeps using the configured manual proxy on iOS', () {
      final proxy = DebugSystemProxy.selectProxy(
        isAndroid: false,
        isIOS: true,
        androidSystemProxyEnabled: true,
        androidSystemProxy: 'PROXY 192.168.1.10:8888',
        iosProxy: '  PROXY 192.168.1.20:9090  ',
      );

      expect(proxy, 'PROXY 192.168.1.20:9090');
    });

    test('does not configure a proxy on unsupported platforms', () {
      final proxy = DebugSystemProxy.selectProxy(
        isAndroid: false,
        isIOS: false,
        androidSystemProxyEnabled: true,
        androidSystemProxy: 'PROXY 192.168.1.10:8888',
        iosProxy: 'PROXY 192.168.1.20:9090',
      );

      expect(proxy, isEmpty);
    });
  });
}
