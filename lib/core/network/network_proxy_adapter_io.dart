import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureNetworkProxy(Dio dio, {required String proxy}) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (_) => proxy;
      return client;
    },
  );
}
