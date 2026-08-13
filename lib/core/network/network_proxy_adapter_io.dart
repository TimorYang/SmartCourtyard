import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        client.findProxy = (uri) {
          if (kDebugMode) {
            debugPrint(
              '[FLINX][Network] Proxy route selected: ${uri.host} -> $proxy',
            );
          }
          return proxy;
        };
      }
      if (allowInvalidCertificates) {
        client.badCertificateCallback = (_, _, _) => true;
      }
      return client;
    },
  );
}
