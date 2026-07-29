import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureDebugNetworkProxy(
  Dio dio, {
  required String proxy,
  required bool allowInvalidCertificates,
}) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      if (proxy.isNotEmpty) {
        client.findProxy = (_) => proxy;
      }
      if (allowInvalidCertificates) {
        client.badCertificateCallback = (_, _, _) => true;
      }
      return client;
    },
  );
}
