import 'package:dio/dio.dart';

import 'network_proxy_adapter_stub.dart'
    if (dart.library.io) 'network_proxy_adapter_io.dart'
    as implementation;

/// Configures a proxy on the supplied Dio instance without changing TLS rules.
void configureNetworkProxy(Dio dio, {required String proxy}) {
  implementation.configureNetworkProxy(dio, proxy: proxy);
}
