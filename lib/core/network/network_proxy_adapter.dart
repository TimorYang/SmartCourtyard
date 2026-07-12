import 'package:dio/dio.dart';

import 'network_proxy_adapter_stub.dart'
    if (dart.library.io) 'network_proxy_adapter_io.dart'
    as implementation;

/// Configures an opt-in debugging proxy without changing production TLS rules.
void configureDebugNetworkProxy(
  Dio dio, {
  required String proxy,
  required bool allowInvalidCertificates,
}) {
  implementation.configureDebugNetworkProxy(
    dio,
    proxy: proxy,
    allowInvalidCertificates: allowInvalidCertificates,
  );
}
