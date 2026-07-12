import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_api_configuration.dart';
import '../logging/app_logger.dart';
import 'network_debug_settings.dart';
import 'network_proxy_adapter.dart';

abstract final class NetworkRequestExtras {
  static const requestId = 'requestId';
}

abstract final class NetworkHeaders {
  static const requestId = 'X-Request-Id';
}

class DioFactory {
  const DioFactory._();

  static Dio create({
    required AppApiConfiguration configuration,
    required AppLogger logger,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: configuration.apiBaseUri.toString(),
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );
    if (kDebugMode &&
        (NetworkDebugSettings.proxy.trim().isNotEmpty ||
            NetworkDebugSettings.allowInvalidProxyCertificates)) {
      configureDebugNetworkProxy(
        dio,
        proxy: NetworkDebugSettings.proxy.trim(),
        allowInvalidCertificates:
            NetworkDebugSettings.allowInvalidProxyCertificates,
      );
    }
    dio.interceptors.addAll([
      _RequestIdInterceptor(),
      _SafeNetworkLogInterceptor(logger),
    ]);
    return dio;
  }
}

class _RequestIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestId = options.extra[NetworkRequestExtras.requestId];
    if (requestId is String && requestId.isNotEmpty) {
      options.headers.putIfAbsent(NetworkHeaders.requestId, () => requestId);
    }
    handler.next(options);
  }
}

class _SafeNetworkLogInterceptor extends Interceptor {
  _SafeNetworkLogInterceptor(this._logger);

  final AppLogger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.info(
      'HTTP request started.',
      requestId: _requestId(options),
      context: {'method': options.method, 'path': options.path},
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.info(
      'HTTP request completed.',
      requestId: _requestId(response.requestOptions),
      context: {
        'method': response.requestOptions.method,
        'path': response.requestOptions.path,
        'statusCode': response.statusCode,
      },
    );
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[FLINX][DIO] Raw failure: $error');
      debugPrintStack(
        label: '[FLINX][DIO] Raw failure stack trace',
        stackTrace: error.stackTrace,
      );
    }
    _logger.warning(
      'HTTP request failed.',
      requestId: _requestId(error.requestOptions),
      context: {
        'method': error.requestOptions.method,
        'path': error.requestOptions.path,
        'statusCode': error.response?.statusCode,
        'errorType': error.type.name,
        'reason': error.error?.toString() ?? error.message,
      },
    );
    handler.next(error);
  }

  String? _requestId(RequestOptions options) {
    final value = options.extra[NetworkRequestExtras.requestId];
    return value is String && value.isNotEmpty ? value : null;
  }
}
