import 'package:dio/dio.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/core/network/startup_network_access_probe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'issues a lightweight GET request to trigger initial network access',
    () async {
      final adapter = _CapturingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final probe = StartupNetworkAccessProbe(
        logger: _FakeLogger(),
        dio: dio,
        requestIdGenerator: () => 'startup-request-123',
      );

      await probe.trigger();

      expect(adapter.requestOptions.method, 'GET');
      expect(adapter.requestOptions.uri.toString(), 'https://www.baidu.com');
      expect(
        adapter.requestOptions.headers[NetworkHeaders.requestId],
        'startup-request-123',
      );
    },
  );
}

class _CapturingAdapter implements HttpClientAdapter {
  late RequestOptions requestOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestOptions = options;
    return ResponseBody.fromString('', 204);
  }
}

class _FakeLogger implements AppLogger {
  @override
  void error(
    String message, {
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void info(
    String message, {
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void warning(
    String message, {
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}
}
