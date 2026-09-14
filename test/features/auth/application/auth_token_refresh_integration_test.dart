import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flinx/app/session/network_session_handlers.dart';
import 'package:flinx/core/config/app_api_configuration.dart';
import 'package:flinx/core/config/providers.dart';
import 'package:flinx/core/network/access_token_cache.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/core/network/providers.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/login_device_context.dart';
import 'package:flinx/features/auth/domain/services/login_device_context_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(AccessTokenCache.clear);

  test(
    'refreshes through the shared Dio before sending business requests',
    () async {
      final harness = await _createHarness();

      await harness.dio.get<void>(
        'app/home/scenes',
        options: Options(
          extra: {NetworkRequestExtras.requestId: 'home-request'},
        ),
      );

      expect(harness.adapter.requests.map((request) => request.path), [
        'app/auth/refresh',
        'app/home/scenes',
      ]);
      final request = harness.adapter.requests.last;
      expect(request.headers[NetworkHeaders.bladeAuth], 'new-access-token');
      expect(request.headers[NetworkHeaders.requestId], 'home-request');
      final tokens = await harness.container
          .read(accountRepositoryProvider)
          .readTokenSet();
      expect(tokens?.refreshToken, 'new-refresh-token');
      expect(tokens?.isUsableAt(DateTime.now()), isTrue);
    },
    timeout: const Timeout(Duration(seconds: 5)),
  );

  test(
    'concurrent business requests share one token refresh',
    () async {
      final harness = await _createHarness();

      await Future.wait([
        harness.dio.get<void>('app/home/scenes'),
        harness.dio.get<void>('app/account/profile'),
      ]);

      expect(
        harness.adapter.requests.where(
          (request) => request.path == 'app/auth/refresh',
        ),
        hasLength(1),
      );
      final businessRequests = harness.adapter.requests.where(
        (request) => !request.path.startsWith('app/auth/'),
      );
      expect(businessRequests, hasLength(2));
      expect(
        businessRequests.map(
          (request) => request.headers[NetworkHeaders.bladeAuth],
        ),
        everyElement('new-access-token'),
      );
    },
    timeout: const Timeout(Duration(seconds: 5)),
  );

  test(
    'a refresh timeout finishes the request and allows a later retry',
    () async {
      final harness = await _createHarness();
      harness.adapter.failNextRefresh = true;

      await expectLater(
        harness.dio.get<void>('app/home/scenes'),
        throwsA(
          isA<DioException>().having(
            (error) => error.type,
            'type',
            DioExceptionType.receiveTimeout,
          ),
        ),
      );

      expect(
        harness.container.read(activeAuthSessionProvider).isAuthenticated,
        isTrue,
      );
      expect(AccessTokenCache.value, 'expired-access-token');
      final tokens = await harness.container
          .read(accountRepositoryProvider)
          .readTokenSet();
      expect(tokens?.refreshToken, 'refresh-token');
      await harness.dio.get<void>('app/home/scenes');

      expect(harness.adapter.requests.map((request) => request.path), [
        'app/auth/refresh',
        'app/auth/refresh',
        'app/home/scenes',
      ]);
      expect(AccessTokenCache.value, 'new-access-token');
    },
    timeout: const Timeout(Duration(seconds: 5)),
  );

  test(
    'expired refresh tokens clear the session and allow login again',
    () async {
      final harness = await _createHarness(refreshExpired: true);

      await expectLater(
        harness.dio.get<void>('app/home/scenes'),
        throwsA(
          isA<DioException>().having(
            (error) => error.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );

      expect(harness.adapter.requests, isEmpty);
      await _expectClearedSessionAndRelogin(harness);
    },
    timeout: const Timeout(Duration(seconds: 5)),
  );

  for (final httpStatus in [200, 401]) {
    test(
      'HTTP $httpStatus with code 401 clears the session through app wiring',
      () async {
        final harness = await _createHarness(accessExpired: false);
        harness.adapter.unauthorizedStatus = httpStatus;

        final request = harness.dio.get<void>('app/home/scenes');
        if (httpStatus == 401) {
          await expectLater(request, throwsA(isA<DioException>()));
        } else {
          await request;
        }

        await _expectClearedSessionAndRelogin(harness);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );
  }
}

Future<_Harness> _createHarness({
  bool accessExpired = true,
  bool refreshExpired = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      appApiConfigurationProvider.overrideWithValue(
        const AppApiConfiguration(
          apiOrigin: 'https://api.flinx.example',
          apiPathPrefix: '/api/force-door',
        ),
      ),
      loginDeviceContextProvider.overrideWithValue(
        const _DeviceContextProvider(),
      ),
      sessionExpiredHandlerProvider.overrideWith(createSessionExpiredHandler),
      tokenRefreshHandlerProvider.overrideWith(createTokenRefreshHandler),
    ],
  );
  addTearDown(container.dispose);
  final adapter = _RefreshAdapter();
  final dio = container.read(dioProvider)..httpClientAdapter = adapter;
  addTearDown(() => dio.close(force: true));
  await container
      .read(accountRepositoryProvider)
      .saveTokenSet(
        AccountTokenSet(
          accessToken: 'expired-access-token',
          refreshToken: 'refresh-token',
          expiresAt: accessExpired
              ? DateTime.utc(2020)
              : DateTime.now().toUtc().add(const Duration(hours: 1)),
          refreshExpiresAt: refreshExpired
              ? DateTime.utc(2020)
              : DateTime.now().toUtc().add(const Duration(days: 1)),
        ),
      );
  container
      .read(activeAuthSessionProvider.notifier)
      .markAuthenticated(userId: 'user-1');
  return _Harness(container, dio, adapter);
}

Future<void> _expectClearedSessionAndRelogin(_Harness harness) async {
  final session = harness.container.read(activeAuthSessionProvider);
  expect(session.isAuthenticated, isFalse);
  expect(session.canRestoreFromCache, isFalse);
  expect(AccessTokenCache.value, isNull);
  final repository = harness.container.read(accountRepositoryProvider);
  expect(await repository.readTokenSet(), isNull);

  await harness.dio.post<void>('app/auth/login');
  expect(harness.adapter.requests.last.path, 'app/auth/login');
  await repository.saveTokenSet(
    AccountTokenSet(
      accessToken: 'relogin-access-token',
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    ),
  );
  harness.container
      .read(activeAuthSessionProvider.notifier)
      .markAuthenticated(userId: 'user-1');
  await harness.dio.get<void>('app/home/scenes');
  expect(
    harness.adapter.requests.last.headers[NetworkHeaders.bladeAuth],
    'relogin-access-token',
  );
}

class _Harness {
  const _Harness(this.container, this.dio, this.adapter);

  final ProviderContainer container;
  final Dio dio;
  final _RefreshAdapter adapter;
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

class _RefreshAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool failNextRefresh = false;
  int? unauthorizedStatus;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.path == 'app/auth/refresh' && failNextRefresh) {
      failNextRefresh = false;
      throw DioException.receiveTimeout(
        timeout: const Duration(seconds: 15),
        requestOptions: options,
      );
    }
    final status = unauthorizedStatus;
    if (status != null) {
      unauthorizedStatus = null;
      return ResponseBody.fromString(
        jsonEncode({'code': 401, 'success': false}),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'code': 200,
        'success': true,
        if (options.path == 'app/auth/refresh')
          'data': {
            'access_token': 'new-access-token',
            'refresh_token': 'new-refresh-token',
            'token_type': 'Bearer',
            'expires_in': 7200,
            'refresh_expires_in': 2592000,
          },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
