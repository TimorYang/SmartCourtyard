import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flinx/core/config/app_api_configuration.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/access_token_cache.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/core/network/session_expired_handler.dart';
import 'package:flinx/features/account/data/data_sources/account_local_data_source.dart';
import 'package:flinx/features/account/data/data_sources/account_secure_data_source.dart';
import 'package:flinx/features/account/data/repositories/account_repository_impl.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';
import 'package:flinx/features/auth/data/data_sources/auth_api.dart';
import 'package:flinx/features/auth/data/services/auth_token_refresh_service.dart';
import 'package:flinx/features/auth/domain/entities/login_device_context.dart';
import 'package:flinx/features/auth/domain/services/login_device_context_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(AccessTokenCache.clear);

  test(
    'refreshes and persists both tokens when the refresh token is valid',
    () async {
      final adapter = _RefreshResponseAdapter(
        body: {
          'code': 200,
          'success': true,
          'data': {
            'account': 'user@example.com',
            'account_id': 'account-1',
            'user_id': 'user-1',
            'user_name': 'User',
            'access_token': 'new-access-token',
            'refresh_token': 'new-refresh-token',
            'token_type': 'Bearer',
            'expires_in': 7200,
            'refresh_expires_in': 2592000,
          },
          'msg': '',
        },
      );
      final repository = await _repositoryWithExpiredAccessToken(
        refreshExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
      );
      final service = AuthTokenRefreshService(
        api: AuthApi(
          DioFactory.create(
            configuration: const AppApiConfiguration(
              apiOrigin: 'https://api.flinx.example',
              apiPathPrefix: '/force-door',
              clientAuthorization: 'encoded-client-credentials',
            ),
            logger: const _TestLogger(),
          )..httpClientAdapter = adapter,
        ),
        accountRepository: repository,
        deviceContextProvider: const _DeviceContextProvider(),
      );

      final result = await service.refreshExpiredAccessToken();

      expect(result, TokenRefreshResult.refreshed);
      expect(adapter.requestBody, {
        'refreshToken': 'old-refresh-token',
        'deviceId': 'installation-id',
      });
      final tokenSet = await repository.readTokenSet();
      expect(tokenSet?.accessToken, 'new-access-token');
      expect(tokenSet?.refreshToken, 'new-refresh-token');
      expect(tokenSet?.isUsableAt(DateTime.now()), isTrue);
      expect(tokenSet?.isRefreshUsableAt(DateTime.now()), isTrue);
      expect(AccessTokenCache.value, 'new-access-token');
      expect(
        adapter.requestOptions.headers[NetworkHeaders.authorization],
        'Basic encoded-client-credentials',
      );
    },
  );

  test('does not call refresh when the refresh token has expired', () async {
    final adapter = _RefreshResponseAdapter(body: const {});
    final repository = await _repositoryWithExpiredAccessToken(
      refreshExpiresAt: DateTime.utc(2020),
    );
    final service = AuthTokenRefreshService(
      api: AuthApi(
        Dio(BaseOptions(baseUrl: 'https://api.flinx.example/force-door'))
          ..httpClientAdapter = adapter,
      ),
      accountRepository: repository,
      deviceContextProvider: const _DeviceContextProvider(),
    );

    final result = await service.refreshExpiredAccessToken();

    expect(result, TokenRefreshResult.sessionExpired);
    expect(adapter.wasCalled, isFalse);
  });
}

Future<AccountRepositoryImpl> _repositoryWithExpiredAccessToken({
  required DateTime refreshExpiresAt,
}) async {
  final repository = AccountRepositoryImpl(
    localDataSource: InMemoryAccountLocalDataSource(),
    secureDataSource: InMemoryAccountSecureDataSource(),
  );
  await repository.saveTokenSet(
    AccountTokenSet(
      accessToken: 'old-access-token',
      refreshToken: 'old-refresh-token',
      expiresAt: DateTime.utc(2020),
      refreshExpiresAt: refreshExpiresAt,
    ),
  );
  return repository;
}

class _DeviceContextProvider implements LoginDeviceContextProvider {
  const _DeviceContextProvider();

  @override
  Future<LoginDeviceContext> read() async => const LoginDeviceContext(
    deviceId: 'installation-id',
    deviceModel: 'Test device',
    platform: 'IOS',
    appVersion: '1.0.0',
  );
}

class _RefreshResponseAdapter implements HttpClientAdapter {
  _RefreshResponseAdapter({required this.body});

  final Map<String, dynamic> body;
  Map<String, dynamic>? requestBody;
  late RequestOptions requestOptions;
  bool wasCalled = false;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    wasCalled = true;
    requestOptions = options;
    requestBody = Map<String, dynamic>.from(options.data as Map);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _TestLogger implements AppLogger {
  const _TestLogger();

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
