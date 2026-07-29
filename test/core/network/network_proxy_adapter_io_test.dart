import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flinx/core/network/network_proxy_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('configures only the supplied Dio instance', () {
    final previousOverrides = HttpOverrides.current;
    final sentinelOverrides = _SentinelHttpOverrides();
    HttpOverrides.global = sentinelOverrides;
    addTearDown(() => HttpOverrides.global = previousOverrides);

    final dio = Dio();
    configureDebugNetworkProxy(
      dio,
      proxy: 'PROXY 192.168.1.66:8887',
      allowInvalidCertificates: true,
    );

    expect(HttpOverrides.current, same(sentinelOverrides));
    expect(dio.httpClientAdapter, isA<IOHttpClientAdapter>());
  });
}

class _SentinelHttpOverrides extends HttpOverrides {}
