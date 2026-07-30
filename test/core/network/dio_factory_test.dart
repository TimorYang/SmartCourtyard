import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flinx/core/config/app_api_configuration.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/access_token_cache.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/core/network/network_exception.dart';
import 'package:flinx/core/network/session_expired_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'adds the correlated request id without logging request content',
    () async {
      final adapter = _CapturingAdapter();
      final dio = DioFactory.create(
        configuration: const AppApiConfiguration(
          apiOrigin: 'https://api.flinx.example',
          apiPathPrefix: '/api/force-door',
        ),
        logger: _FakeLogger(),
      )..httpClientAdapter = adapter;

      await dio.get<void>(
        'health',
        options: Options(
          extra: {NetworkRequestExtras.requestId: 'request-123'},
        ),
      );

      expect(
        adapter.requestOptions.uri.toString(),
        'https://api.flinx.example/api/force-door/health',
      );
      expect(
        adapter.requestOptions.headers[NetworkHeaders.requestId],
        'request-123',
      );
    },
  );

  test('maps a bad HTTP response to a network exception with its status', () {
    final options = RequestOptions(path: 'health');
    final exception = NetworkException.fromDio(
      DioException(
        requestOptions: options,
        response: Response<void>(requestOptions: options, statusCode: 503),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(exception.kind, NetworkErrorKind.httpStatus);
    expect(exception.statusCode, 503);
  });

  test('adds Blade-Auth for non-authentication endpoints', () async {
    addTearDown(AccessTokenCache.clear);
    AccessTokenCache.set('access-token');
    final adapter = _CapturingAdapter();
    final dio = DioFactory.create(
      configuration: const AppApiConfiguration(
        apiOrigin: 'https://api.flinx.example',
        apiPathPrefix: '/api/force-door',
      ),
      logger: _FakeLogger(),
    )..httpClientAdapter = adapter;

    await dio.get<void>('app/account/profile');

    expect(
      adapter.requestOptions.headers[NetworkHeaders.bladeAuth],
      'access-token',
    );
  });

  test(
    'refreshes an expired access token before sending a protected request',
    () async {
      addTearDown(AccessTokenCache.clear);
      AccessTokenCache.set(
        'expired-access-token',
        expiresAt: DateTime.utc(2020),
      );
      var refreshCount = 0;
      final adapter = _CapturingAdapter();
      final dio = DioFactory.create(
        configuration: const AppApiConfiguration(
          apiOrigin: 'https://api.flinx.example',
          apiPathPrefix: '/api/force-door',
        ),
        logger: _FakeLogger(),
        onTokenRefresh: () async {
          refreshCount++;
          AccessTokenCache.set(
            'refreshed-access-token',
            expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          );
          return TokenRefreshResult.refreshed;
        },
      )..httpClientAdapter = adapter;

      await dio.get<void>('app/home/scenes');

      expect(refreshCount, 1);
      expect(
        adapter.requestOptions.headers[NetworkHeaders.bladeAuth],
        'refreshed-access-token',
      );
    },
  );

  test(
    'does not refresh a request that explicitly skips token refresh',
    () async {
      addTearDown(AccessTokenCache.clear);
      AccessTokenCache.set(
        'expired-access-token',
        expiresAt: DateTime.utc(2020),
      );
      var refreshCount = 0;
      final adapter = _CapturingAdapter();
      final dio = DioFactory.create(
        configuration: const AppApiConfiguration(
          apiOrigin: 'https://api.flinx.example',
          apiPathPrefix: '/api/force-door',
        ),
        logger: _FakeLogger(),
        onTokenRefresh: () async {
          refreshCount++;
          return TokenRefreshResult.refreshed;
        },
      )..httpClientAdapter = adapter;

      await dio.get<void>(
        'app/account/profile',
        options: Options(extra: {NetworkRequestExtras.skipTokenRefresh: true}),
      );

      expect(refreshCount, 0);
      expect(
        adapter.requestOptions.headers[NetworkHeaders.bladeAuth],
        'expired-access-token',
      );
    },
  );

  test(
    'notifies the session handler when a response body contains code 401',
    () async {
      addTearDown(AccessTokenCache.clear);
      AccessTokenCache.set('expired-access-token');
      var sessionExpiredCount = 0;
      final dio =
          DioFactory.create(
              configuration: const AppApiConfiguration(
                apiOrigin: 'https://api.flinx.example',
                apiPathPrefix: '/api/force-door',
              ),
              logger: _FakeLogger(),
              onSessionExpired: () async => sessionExpiredCount++,
            )
            ..httpClientAdapter = _JsonResponseAdapter(
              statusCode: 200,
              body: {'code': 401, 'success': false},
            );

      await dio.get<void>('app/home/scenes');

      expect(sessionExpiredCount, 1);
      expect(AccessTokenCache.value, isNull);
    },
  );

  test('notifies the session handler for an HTTP status 401', () async {
    addTearDown(AccessTokenCache.clear);
    AccessTokenCache.set('expired-access-token');
    var sessionExpiredCount = 0;
    final dio =
        DioFactory.create(
            configuration: const AppApiConfiguration(
              apiOrigin: 'https://api.flinx.example',
              apiPathPrefix: '/api/force-door',
            ),
            logger: _FakeLogger(),
            onSessionExpired: () async => sessionExpiredCount++,
          )
          ..httpClientAdapter = _JsonResponseAdapter(
            statusCode: 401,
            body: {'code': 200, 'success': false},
          );

    await expectLater(
      dio.get<void>('app/home/scenes'),
      throwsA(isA<DioException>()),
    );

    expect(sessionExpiredCount, 1);
    expect(AccessTokenCache.value, isNull);
  });

  test(
    'does not expire a session for an HTTP 401 from an auth endpoint',
    () async {
      addTearDown(AccessTokenCache.clear);
      AccessTokenCache.set('access-token');
      var sessionExpiredCount = 0;
      final dio =
          DioFactory.create(
              configuration: const AppApiConfiguration(
                apiOrigin: 'https://api.flinx.example',
                apiPathPrefix: '/api/force-door',
              ),
              logger: _FakeLogger(),
              onSessionExpired: () async => sessionExpiredCount++,
            )
            ..httpClientAdapter = _JsonResponseAdapter(
              statusCode: 401,
              body: {'code': 401, 'success': false},
            );

      await expectLater(
        dio.post<void>('app/auth/login'),
        throwsA(isA<DioException>()),
      );

      expect(sessionExpiredCount, 0);
      expect(AccessTokenCache.value, 'access-token');
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
    return ResponseBody.fromString(
      jsonEncode({'code': 200, 'success': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _FakeLogger implements AppLogger {
  @override
  void error(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void info(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void warning(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}
}

class _JsonResponseAdapter implements HttpClientAdapter {
  _JsonResponseAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, Object> body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
