import 'package:flinx/app/session/session_cleanup_coordinator.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/logging/providers.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/data/data_sources/account_local_data_source.dart';
import 'package:flinx/features/account/data/data_sources/account_secure_data_source.dart';
import 'package:flinx/features/account/data/dto/account_profile_dto.dart';
import 'package:flinx/features/account/domain/entities/account_overview.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';
import 'package:flinx/features/account/domain/repositories/account_overview_repository.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/auth_session.dart';
import 'package:flinx/features/push/application/providers.dart';
import 'package:flinx/features/push/data/noop_push_gateway.dart';
import 'package:flinx/features/push/domain/entities/push_configuration.dart';
import 'package:flinx/features/push/domain/entities/push_registration.dart';
import 'package:flinx/features/push/domain/repositories/push_registration_repository.dart';
import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unbinds before clearing the access token', () async {
    final harness = _createHarness();
    addTearDown(harness.container.dispose);

    await harness.container.read(sessionCleanupCoordinatorProvider).signOut();

    expect(
      harness.events.indexOf('push-unbind'),
      lessThan(harness.events.indexOf('clear-token')),
    );
    expect(
      harness.container.read(activeAuthSessionProvider).isAuthenticated,
      isFalse,
    );
  });

  test('continues local logout when unbind fails', () async {
    final harness = _createHarness(unbindError: StateError('offline'));
    addTearDown(harness.container.dispose);

    await harness.container.read(sessionCleanupCoordinatorProvider).signOut();

    expect(harness.events, contains('push-unbind'));
    expect(harness.events, contains('clear-token'));
    expect(
      harness.container.read(activeAuthSessionProvider).isAuthenticated,
      isFalse,
    );
  });

  test('does not call push unbind for expired sessions', () async {
    final harness = _createHarness();
    addTearDown(harness.container.dispose);

    await harness.container
        .read(sessionCleanupCoordinatorProvider)
        .clearExpiredSession();

    expect(harness.events, isNot(contains('push-unbind')));
    expect(harness.events, contains('clear-token'));
  });
}

_CleanupHarness _createHarness({Object? unbindError}) {
  final events = <String>[];
  final pushRepository = _TrackingPushRegistrationRepository(
    events: events,
    unbindError: unbindError,
  );
  final localDataSource = _TrackingAccountLocalDataSource(events);
  final secureDataSource = _TrackingAccountSecureDataSource(events);

  final container = ProviderContainer(
    overrides: [
      appLoggerProvider.overrideWithValue(const _TestLogger()),
      pushConfigurationProvider.overrideWithValue(
        const PushConfiguration(
          appKey: 'test-app-key',
          channel: 'test',
          iosProduction: false,
        ),
      ),
      pushGatewayProvider.overrideWithValue(const NoopPushGateway()),
      pushHardwareGatewayProvider.overrideWithValue(MockHardwareGateway()),
      pushRegistrationRepositoryProvider.overrideWithValue(pushRepository),
      authSessionProvider.overrideWith(
        (ref) async =>
            const AuthSession(isAuthenticated: true, userId: 'user-1'),
      ),
      accountLocalDataSourceProvider.overrideWithValue(localDataSource),
      accountSecureDataSourceProvider.overrideWithValue(secureDataSource),
      accountOverviewRepositoryProvider.overrideWithValue(
        _TrackingAccountOverviewRepository(events),
      ),
      homeDeviceListsInvalidatorProvider.overrideWithValue(
        () => events.add('home-invalidated'),
      ),
    ],
  );
  return _CleanupHarness(
    container: container,
    events: events,
    pushRepository: pushRepository,
  );
}

class _CleanupHarness {
  const _CleanupHarness({
    required this.container,
    required this.events,
    required this.pushRepository,
  });

  final ProviderContainer container;
  final List<String> events;
  final _TrackingPushRegistrationRepository pushRepository;
}

class _TrackingPushRegistrationRepository
    implements PushRegistrationRepository {
  _TrackingPushRegistrationRepository({required this.events, this.unbindError});

  final List<String> events;
  final Object? unbindError;

  @override
  Future<void> bind({
    required PushRegistration registration,
    required String requestId,
  }) async {}

  @override
  Future<void> unbind({required String requestId}) async {
    events.add('push-unbind');
    final error = unbindError;
    if (error != null) throw error;
  }
}

class _TrackingAccountLocalDataSource implements AccountLocalDataSource {
  _TrackingAccountLocalDataSource(this.events);

  final List<String> events;
  final _delegate = InMemoryAccountLocalDataSource();

  @override
  Future<AccountProfileDto?> readProfile() => _delegate.readProfile();

  @override
  Stream<AccountProfileDto?> watchProfile() => _delegate.watchProfile();

  @override
  Future<void> saveProfile(AccountProfileDto profile) =>
      _delegate.saveProfile(profile);

  @override
  Future<void> clearProfile() async {
    events.add('clear-profile');
    await _delegate.clearProfile();
  }
}

class _TrackingAccountSecureDataSource implements AccountSecureDataSource {
  _TrackingAccountSecureDataSource(this.events);

  final List<String> events;
  final _delegate = InMemoryAccountSecureDataSource();

  @override
  Future<AccountTokenSet?> readTokenSet() => _delegate.readTokenSet();

  @override
  Future<void> saveTokenSet(AccountTokenSet tokenSet) =>
      _delegate.saveTokenSet(tokenSet);

  @override
  Future<void> clearTokenSet() async {
    events.add('clear-token');
    await _delegate.clearTokenSet();
  }
}

class _TrackingAccountOverviewRepository implements AccountOverviewRepository {
  _TrackingAccountOverviewRepository(this.events);

  final List<String> events;

  @override
  Future<AccountOverview?> readCachedOverview() async => null;

  @override
  Future<AccountOverview> refreshOverview({required String requestId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> clearCachedOverview() async {
    events.add('clear-overview');
  }
}

class _TestLogger implements AppLogger {
  const _TestLogger();

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
}
