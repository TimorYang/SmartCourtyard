import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureDebugNetworkProxy(
  Dio dio, {
  required String proxy,
  required bool allowInvalidCertificates,
}) {
  HttpOverrides.global = _DebugNetworkHttpOverrides(
    proxy: proxy,
    allowInvalidCertificates: allowInvalidCertificates,
  );
  dio.httpClientAdapter = IOHttpClientAdapter();
}

class _DebugNetworkHttpOverrides extends HttpOverrides {
  _DebugNetworkHttpOverrides({
    required this.proxy,
    required this.allowInvalidCertificates,
  });

  final String proxy;
  final bool allowInvalidCertificates;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    if (allowInvalidCertificates) {
      client.badCertificateCallback = (_, _, _) => true;
    }
    return client;
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    return proxy.isNotEmpty
        ? proxy
        : super.findProxyFromEnvironment(url, environment);
  }
}
