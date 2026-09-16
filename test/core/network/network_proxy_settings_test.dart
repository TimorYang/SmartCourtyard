import 'package:flinx/core/network/network_proxy_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to a disabled empty configuration', () {
    const settings = NetworkProxySettings.disabled();

    expect(settings.enabled, isFalse);
    expect(settings.host, isEmpty);
    expect(settings.port, isNull);
    expect(settings.isValid, isTrue);
    expect(settings.isActive, isFalse);
    expect(settings.proxyExpression, isNull);
  });

  test(
    'validates an enabled host and port and builds the proxy expression',
    () {
      const settings = NetworkProxySettings(
        enabled: true,
        host: ' proxy.example.test ',
        port: 9090,
      );

      expect(settings.isValid, isTrue);
      expect(settings.isActive, isTrue);
      expect(settings.normalized().host, 'proxy.example.test');
      expect(settings.proxyExpression, 'PROXY proxy.example.test:9090');
    },
  );

  test('brackets IPv6 literals in the proxy expression', () {
    const settings = NetworkProxySettings(
      enabled: true,
      host: '2001:db8::10',
      port: 8080,
    );
    const alreadyBracketed = NetworkProxySettings(
      enabled: true,
      host: '[2001:db8::10]',
      port: 8080,
    );

    expect(settings.isValid, isTrue);
    expect(settings.proxyExpression, 'PROXY [2001:db8::10]:8080');
    expect(alreadyBracketed.isValid, isTrue);
    expect(alreadyBracketed.proxyExpression, 'PROXY [2001:db8::10]:8080');
  });

  test('rejects schemes, paths, ports, and out-of-range ports', () {
    for (final host in <String>[
      '',
      'http://proxy.example.test',
      'proxy.example.test/path',
      'proxy.example.test:8080',
      '[127.0.0.1]',
      '[2001:db8::10',
    ]) {
      expect(NetworkProxySettings.isValidHost(host), isFalse, reason: host);
    }

    for (final port in <int?>[null, 0, -1, 65536]) {
      expect(NetworkProxySettings.isValidPort(port), isFalse, reason: '$port');
    }
  });

  test('invalid enabled JSON falls back to disabled settings', () {
    expect(
      NetworkProxySettings.fromJson({
        'enabled': true,
        'host': 'proxy.example.test',
        'port': 70000,
      }),
      const NetworkProxySettings.disabled(),
    );
    expect(
      NetworkProxySettings.fromJson('not an object'),
      const NetworkProxySettings.disabled(),
    );
  });

  test('serializes and parses a valid configuration', () {
    const settings = NetworkProxySettings(
      enabled: true,
      host: 'proxy.example.test',
      port: 8888,
    );

    expect(NetworkProxySettings.fromJson(settings.toJson()), settings);
  });
}
