import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flinx/core/config/app_api_configuration.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/core/network/network_proxy_adapter.dart';
import 'package:flinx/core/network/network_proxy_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('configures only the supplied Dio instance', () {
    final previousOverrides = HttpOverrides.current;
    final sentinelOverrides = _SentinelHttpOverrides();
    HttpOverrides.global = sentinelOverrides;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final dio = Dio();
    configureNetworkProxy(dio, proxy: 'PROXY 192.168.1.66:8887');

    expect(HttpOverrides.current, same(sentinelOverrides));
    expect(dio.httpClientAdapter, isA<IOHttpClientAdapter>());
  });

  test(
    'DioFactory applies the manual proxy without changing TLS validation',
    () {
      final dio = DioFactory.create(
        configuration: const AppApiConfiguration(
          apiOrigin: 'https://api.flinx.example',
          apiPathPrefix: '/api/force-door',
        ),
        logger: const DebugAppLogger(),
        proxySettings: const NetworkProxySettings(
          enabled: true,
          host: 'proxy.example.test',
          port: 9090,
        ),
      );
      addTearDown(() => dio.close(force: true));

      final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
      expect(adapter.createHttpClient, isNotNull);
      expect(adapter.validateCertificate, isNull);
    },
  );

  test('DioFactory leaves the default IO adapter untouched when disabled', () {
    final dio = DioFactory.create(
      configuration: const AppApiConfiguration(
        apiOrigin: 'https://api.flinx.example',
        apiPathPrefix: '/api/force-door',
      ),
      logger: const DebugAppLogger(),
      proxySettings: const NetworkProxySettings(
        enabled: false,
        host: 'proxy.example.test',
        port: 9090,
      ),
    );
    addTearDown(() => dio.close(force: true));

    final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
    expect(adapter.createHttpClient, isNull);
    expect(adapter.validateCertificate, isNull);
  });
}

class _SentinelHttpOverrides extends HttpOverrides {}
