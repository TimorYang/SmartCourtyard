import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_api_configuration.dart';
import '../logging/app_logger.dart';
import 'access_token_cache.dart';
import 'debug_system_proxy.dart';
import 'network_debug_settings.dart';
import 'network_proxy_adapter.dart';
import 'session_expired_handler.dart';

abstract final class NetworkRequestExtras {
  static const requestId = 'requestId';
  static const logTag = 'logTag';
  static const flowId = 'flowId';

  /// Skips access-token refresh for a request authenticated with a token that
  /// has not yet been persisted to [AccessTokenCache].
  static const skipTokenRefresh = 'skipTokenRefresh';
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
    SessionExpiredHandler onSessionExpired = ignoreSessionExpired,
    TokenRefreshHandler onTokenRefresh = noTokenRefreshAvailable,
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
    final debugProxy = DebugSystemProxy.proxyForCurrentPlatform(
      iosProxy: NetworkDebugSettings.proxy,
    );
    if (kDebugMode &&
        (debugProxy.isNotEmpty ||
            NetworkDebugSettings.allowInvalidProxyCertificates)) {
      configureDebugNetworkProxy(
        dio,
        proxy: debugProxy,
        allowInvalidCertificates:
            NetworkDebugSettings.allowInvalidProxyCertificates,
      );
      debugPrint(
        '[FLINX][Network] Dio debug proxy configured: '
        '${debugProxy.isEmpty ? 'direct connection' : debugProxy}',
      );
    }
    dio.interceptors.addAll([
      _RequestIdInterceptor(),
      _SessionExpiredInterceptor(
        onSessionExpired: onSessionExpired,
        onTokenRefresh: onTokenRefresh,
      ),
      _BladeAuthInterceptor(),
      _SafeNetworkLogInterceptor(logger),
    ]);
    return dio;
  }
}

class _SessionExpiredInterceptor extends Interceptor {
  _SessionExpiredInterceptor({
    required this._onSessionExpired,
    required this._onTokenRefresh,
  });

  final SessionExpiredHandler _onSessionExpired;
  final TokenRefreshHandler _onTokenRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuthenticationRequest(options) &&
        options.extra[NetworkRequestExtras.skipTokenRefresh] != true &&
        AccessTokenCache.requiresRefresh) {
      final refreshResult = await _onTokenRefresh();
      if (refreshResult == TokenRefreshResult.sessionExpired) {
        await _expireSession();
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            message: 'The authentication session has expired.',
          ),
        );
        return;
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (_isSessionExpiredResponse(response) &&
        !_isAuthenticationRequest(response.requestOptions)) {
      await _expireSession();
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (_isUnauthorizedHttpResponse(error) &&
        !_isAuthenticationRequest(error.requestOptions)) {
      await _expireSession();
    }
    handler.next(error);
  }

  bool _isSessionExpiredResponse(Response<dynamic> response) {
    final data = response.data;
    if (data is! Map) {
      return false;
    }
    final code = data['code'];
    return code == 401 || code == '401';
  }

  bool _isUnauthorizedHttpResponse(DioException error) {
    return error.response?.statusCode == 401;
  }

  bool _isAuthenticationRequest(RequestOptions options) {
    return options.path.startsWith('app/auth/');
  }

  Future<void> _expireSession() async {
    AccessTokenCache.clear();
    await _onSessionExpired();
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
