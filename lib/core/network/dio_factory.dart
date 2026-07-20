import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_api_configuration.dart';
import '../logging/app_logger.dart';
import 'access_token_cache.dart';
import 'network_debug_settings.dart';
import 'network_proxy_adapter.dart';

abstract final class NetworkRequestExtras {
  static const requestId = 'requestId';
  static const logTag = 'logTag';
  static const flowId = 'flowId';
}

abstract final class NetworkHeaders {
  static const requestId = 'X-Request-Id';
  static const bladeAuth = 'Blade-Auth';
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
      _BladeAuthInterceptor(),
      _SafeNetworkLogInterceptor(logger),
    ]);
    return dio;
  }
}

class _BladeAuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.path.startsWith('app/auth/')) {
      final accessToken = AccessTokenCache.value;
      if (accessToken != null) {
        options.headers.putIfAbsent(
          NetworkHeaders.bladeAuth,
          () => accessToken,
        );
      }
    }
    handler.next(options);
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
      tag: _logTag(options),
      flowId: _flowId(options),
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
      tag: _logTag(response.requestOptions),
      flowId: _flowId(response.requestOptions),
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
      tag: _logTag(error.requestOptions),
      flowId: _flowId(error.requestOptions),
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

  String? _flowId(RequestOptions options) {
    final value = options.extra[NetworkRequestExtras.flowId];
    return value is String && value.isNotEmpty ? value : null;
  }

  AppLogTag _logTag(RequestOptions options) {
    final value = options.extra[NetworkRequestExtras.logTag];
    return value is AppLogTag ? value : AppLogTag.general;
  }
}
