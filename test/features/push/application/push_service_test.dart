import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/logging/providers.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/auth_session.dart';
import 'package:flinx/features/auth/domain/entities/login_device_context.dart';
import 'package:flinx/features/auth/domain/services/login_device_context_provider.dart';
import 'package:flinx/features/push/application/providers.dart';
import 'package:flinx/features/push/application/push_registration_sync_guard.dart';
import 'package:flinx/features/push/domain/entities/push_configuration.dart';
import 'package:flinx/features/push/domain/entities/push_event.dart';
import 'package:flinx/features/push/domain/entities/push_registration.dart';
import 'package:flinx/features/push/domain/repositories/push_registration_repository.dart';
import 'package:flinx/features/push/domain/services/push_gateway.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'does not initialize EngageLab before notification permission is granted',
    () async {
      final pushGateway = _FakePushGateway();
      final hardwareGateway = _NotificationPermissionGateway(
        PermissionStatus.denied,
      );
      final container = _createContainer(
        pushGateway: pushGateway,
        hardwareGateway: hardwareGateway,
      );
      addTearDown(container.dispose);

      await container.read(pushServiceProvider.notifier).initialize();

      expect(
        container.read(pushServiceProvider).status,
        PushInitializationStatus.waitingForNotificationPermission,
      );
      expect(pushGateway.initializeCalls, 0);
    },
  );

  test(
    'does not request notification permission before authentication',
    () async {
      final pushGateway = _FakePushGateway();
      final hardwareGateway = _NotificationPermissionGateway(
        PermissionStatus.notDetermined,
      );
      final container = _createContainer(
        pushGateway: pushGateway,
        hardwareGateway: hardwareGateway,
      );
      addTearDown(container.dispose);

      final service = container.read(pushServiceProvider.notifier);
      await service.initialize();
      await _flushMicrotasks();

      expect(hardwareGateway.requestCalls, 0);
      expect(
        container.read(pushServiceProvider).status,
        PushInitializationStatus.waitingForNotificationPermission,
      );
    },
  );

  test(
    'requests notification permission after an authenticated login',
    () async {
      final pushGateway = _FakePushGateway();
      final hardwareGateway = _NotificationPermissionGateway(
        PermissionStatus.notDetermined,
      );
      final container = _createContainer(
        pushGateway: pushGateway,
        hardwareGateway: hardwareGateway,
      );
      addTearDown(container.dispose);

      final service = container.read(pushServiceProvider.notifier);
      await service.initialize();
      container
          .read(activeAuthSessionProvider.notifier)
          .markAuthenticated(userId: 'user-1');
      await container.read(authSessionProvider.future);
      await _flushMicrotasks();

      expect(hardwareGateway.requestCalls, 1);
      expect(pushGateway.initializeCalls, 1);
      expect(
        container.read(pushServiceProvider).status,
        PushInitializationStatus.ready,
      );
    },
  );

  test(
    'requests notification permission for a restored authenticated session',
    () async {
      final pushGateway = _FakePushGateway();
      final hardwareGateway = _NotificationPermissionGateway(
        PermissionStatus.notDetermined,
      );
      final container = _createContainer(
        pushGateway: pushGateway,
        hardwareGateway: hardwareGateway,
        authSession: const AuthSession(isAuthenticated: true, userId: 'user-1'),
      );
      addTearDown(container.dispose);

      final service = container.read(pushServiceProvider.notifier);
      await _initializeAndFlush(service);

      expect(hardwareGateway.requestCalls, 1);
      expect(pushGateway.initializeCalls, 1);
    },
  );

  test(
    'does not request notification permission when it is already granted',
    () async {
      final pushGateway = _FakePushGateway();
      final hardwareGateway = _NotificationPermissionGateway(
        PermissionStatus.granted,
      );
      final container = _createContainer(
        pushGateway: pushGateway,
        hardwareGateway: hardwareGateway,
      );
      addTearDown(container.dispose);

      final service = container.read(pushServiceProvider.notifier);
      await service.initialize();
      container
          .read(activeAuthSessionProvider.notifier)
          .markAuthenticated(userId: 'user-1');
      await container.read(authSessionProvider.future);
      await _flushMicrotasks();

      expect(hardwareGateway.requestCalls, 0);
      expect(pushGateway.initializeCalls, 1);
    },
  );

  test(
    'does not request notification permission when push is not configured',
    () async {
      final pushGateway = _FakePushGateway();
      final hardwareGateway = _NotificationPermissionGateway(
        PermissionStatus.notDetermined,
      );
      final container = _createContainer(
        pushGateway: pushGateway,
        hardwareGateway: hardwareGateway,
        pushConfiguration: const PushConfiguration(
          appKey: '',
          channel: 'test',
          iosProduction: false,
        ),
      );
      addTearDown(container.dispose);

      container.read(pushServiceProvider.notifier);
      container
          .read(activeAuthSessionProvider.notifier)
          .markAuthenticated(userId: 'user-1');
      await container.read(authSessionProvider.future);
      await _flushMicrotasks();

      expect(hardwareGateway.requestCalls, 0);
      expect(pushGateway.initializeCalls, 0);
      expect(
        container.read(pushServiceProvider).status,
        PushInitializationStatus.disabled,
      );
    },
  );

  test(
    'does not request notification permission after it was denied or blocked',
    () async {
      for (final status in <PermissionStatus>[
        PermissionStatus.denied,
        PermissionStatus.blocked,
      ]) {
        final pushGateway = _FakePushGateway();
        final hardwareGateway = _NotificationPermissionGateway(status);
        final container = _createContainer(
          pushGateway: pushGateway,
          hardwareGateway: hardwareGateway,
        );

        final service = container.read(pushServiceProvider.notifier);
        await service.initialize();
        container
            .read(activeAuthSessionProvider.notifier)
            .markAuthenticated(userId: 'user-1');
        await container.read(authSessionProvider.future);
        await _flushMicrotasks();
        service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await _flushMicrotasks();

        expect(hardwareGateway.requestCalls, 0);
        expect(pushGateway.initializeCalls, 0);
        container.dispose();
      }
    },
  );

  test(
    'keeps push waiting when the first permission request is denied',
    () async {
      final pushGateway = _FakePushGateway();
      final hardwareGateway = _NotificationPermissionGateway(
        PermissionStatus.notDetermined,
      )..requestResult = PermissionStatus.blocked;
      final container = _createContainer(
        pushGateway: pushGateway,
        hardwareGateway: hardwareGateway,
      );
      addTearDown(container.dispose);

      final service = container.read(pushServiceProvider.notifier);
      await service.initialize();
      container
          .read(activeAuthSessionProvider.notifier)
          .markAuthenticated(userId: 'user-1');
      await container.read(authSessionProvider.future);
      await _flushMicrotasks();
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _flushMicrotasks();

      expect(hardwareGateway.requestCalls, 1);
      expect(pushGateway.initializeCalls, 0);
      expect(
        container.read(pushServiceProvider).status,
        PushInitializationStatus.waitingForNotificationPermission,
      );
    },
  );

  test(
    'keeps push waiting when the notification permission request fails',
    () async {
      final pushGateway = _FakePushGateway();
      final hardwareGateway =
          _NotificationPermissionGateway(PermissionStatus.notDetermined)
            ..requestHandler = () async {
              throw StateError('permission request failed');
            };
      final container = _createContainer(
        pushGateway: pushGateway,
        hardwareGateway: hardwareGateway,
      );
      addTearDown(container.dispose);

      final service = container.read(pushServiceProvider.notifier);
      await service.initialize();
      container
          .read(activeAuthSessionProvider.notifier)
          .markAuthenticated(userId: 'user-1');
      await container.read(authSessionProvider.future);
      await _flushMicrotasks();

      expect(hardwareGateway.requestCalls, 1);
      expect(pushGateway.initializeCalls, 0);
      expect(
        container.read(pushServiceProvider).status,
        PushInitializationStatus.waitingForNotificationPermission,
      );
    },
  );

  test(
    'deduplicates permission requests during concurrent auth and resume events',
    () async {
      final requestResult = Completer<PermissionStatus>();
      final pushGateway = _FakePushGateway();
      final hardwareGateway = _NotificationPermissionGateway(
        PermissionStatus.notDetermined,
      )..requestHandler = () => requestResult.future;
      final container = _createContainer(
        pushGateway: pushGateway,
        hardwareGateway: hardwareGateway,
      );
      addTearDown(container.dispose);

      final service = container.read(pushServiceProvider.notifier);
      await service.initialize();
      container
          .read(activeAuthSessionProvider.notifier)
          .markAuthenticated(userId: 'user-1');
      await container.read(authSessionProvider.future);
      await _flushMicrotasks();
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _flushMicrotasks();

      expect(hardwareGateway.requestCalls, 1);

      hardwareGateway.notificationStatus = PermissionStatus.granted;
      requestResult.complete(PermissionStatus.granted);
      await _flushMicrotasks();

      expect(pushGateway.initializeCalls, 1);
      expect(
        container.read(pushServiceProvider).status,
        PushInitializationStatus.ready,
      );
    },
  );

  test('initializes once after notification permission is available', () async {
    final pushGateway = _FakePushGateway();
    final hardwareGateway = _NotificationPermissionGateway(
      PermissionStatus.granted,
    );
    final container = _createContainer(
      pushGateway: pushGateway,
      hardwareGateway: hardwareGateway,
    );
    addTearDown(container.dispose);

    final service = container.read(pushServiceProvider.notifier);
    await service.initialize();
    await service.initialize();

    expect(
      container.read(pushServiceProvider).status,
      PushInitializationStatus.ready,
    );
    expect(pushGateway.initializeCalls, 1);
  });

  test(
    'retries initialization after the user grants notification permission',
    () async {
      final pushGateway = _FakePushGateway();
      final hardwareGateway = _NotificationPermissionGateway(
        PermissionStatus.denied,
      );
      final container = _createContainer(
        pushGateway: pushGateway,
        hardwareGateway: hardwareGateway,
      );
      addTearDown(container.dispose);

      final service = container.read(pushServiceProvider.notifier);
      await service.initialize();
      hardwareGateway.notificationStatus = PermissionStatus.granted;
      await service.retryInitialization();

      expect(
        container.read(pushServiceProvider).status,
        PushInitializationStatus.ready,
      );
      expect(pushGateway.initializeCalls, 1);
    },
  );

  test(
    'binds after SDK initialization for a restored authenticated session',
    () async {
      final pushGateway = _FakePushGateway(registrationId: 'registration-1');
      final registrationRepository = _FakePushRegistrationRepository();
      final container = _createContainer(
        pushGateway: pushGateway,
        hardwareGateway: _NotificationPermissionGateway(
          PermissionStatus.granted,
        ),
        authSession: const AuthSession(isAuthenticated: true, userId: 'user-1'),
        registrationRepository: registrationRepository,
        registrationContext: const _FakeLoginDeviceContextProvider(
          deviceId: 'installation-1',
          platform: 'IOS',
        ),
      );
      addTearDown(container.dispose);

      final service = container.read(pushServiceProvider.notifier);
      await _initializeAndFlush(service);

      expect(registrationRepository.bindings, hasLength(1));
      expect(
        registrationRepository.bindings.single.registrationId,
        'registration-1',
      );
      expect(registrationRepository.bindings.single.deviceId, 'installation-1');
      expect(registrationRepository.bindings.single.platform, PushPlatform.ios);
    },
  );

  test(
    'binds after an authenticated user logs in while SDK is ready',
    () async {
      final pushGateway = _FakePushGateway(registrationId: 'registration-1');
      final registrationRepository = _FakePushRegistrationRepository();
      final container = _createContainer(
        pushGateway: pushGateway,
        hardwareGateway: _NotificationPermissionGateway(
          PermissionStatus.granted,
        ),
        registrationRepository: registrationRepository,
        registrationContext: const _FakeLoginDeviceContextProvider(
          deviceId: 'installation-1',
          platform: 'ANDROID',
        ),
      );
      addTearDown(container.dispose);

      final service = container.read(pushServiceProvider.notifier);
      await _initializeAndFlush(service);
      expect(registrationRepository.bindings, isEmpty);

      container
          .read(activeAuthSessionProvider.notifier)
          .markAuthenticated(userId: 'user-1');
      await container.read(authSessionProvider.future);
      await _flushMicrotasks();

      expect(registrationRepository.bindings, hasLength(1));
    },
  );

  test(
    'waits for a delayed registration id and retries on connection',
    () async {
      final pushGateway = _FakePushGateway();
      final registrationRepository = _FakePushRegistrationRepository();
      final container = _createContainer(
        pushGateway: pushGateway,
        hardwareGateway: _NotificationPermissionGateway(
          PermissionStatus.granted,
        ),
        authSession: const AuthSession(isAuthenticated: true, userId: 'user-1'),
        registrationRepository: registrationRepository,
        registrationContext: const _FakeLoginDeviceContextProvider(
          deviceId: 'installation-1',
          platform: 'IOS',
        ),
      );
      addTearDown(container.dispose);

      final service = container.read(pushServiceProvider.notifier);
      await _initializeAndFlush(service);
      expect(registrationRepository.bindings, isEmpty);

      pushGateway.registrationId = 'registration-delayed';
      pushGateway.emit(const PushConnectionChanged(connected: true));
      await _flushMicrotasks();
      await service.retryInitialization();

      expect(registrationRepository.bindings, hasLength(1));
      expect(
        registrationRepository.bindings.single.registrationId,
        'registration-delayed',
      );
    },
  );

  test(
    'merges concurrent binds for the same user and registration id',
    () async {
      final pushGateway = _FakePushGateway();
      final registrationRepository = _FakePushRegistrationRepository();
      final bindGate = Completer<void>();
      registrationRepository.bindGate = bindGate;
      final container = _createContainer(
        pushGateway: pushGateway,
        hardwareGateway: _NotificationPermissionGateway(
          PermissionStatus.granted,
        ),
        authSession: const AuthSession(isAuthenticated: true, userId: 'user-1'),
        registrationRepository: registrationRepository,
        registrationContext: const _FakeLoginDeviceContextProvider(
          deviceId: 'installation-1',
          platform: 'IOS',
        ),
      );
      addTearDown(container.dispose);

      final service = container.read(pushServiceProvider.notifier);
      await _initializeAndFlush(service);
      pushGateway.registrationId = 'registration-1';
      pushGateway.emit(const PushConnectionChanged(connected: true));
      await _flushMicrotasks();

      final first = service.retryInitialization();
      final second = service.retryInitialization();
      await _flushMicrotasks();
      expect(registrationRepository.bindCalls, 1);

      bindGate.complete();
      await Future.wait([first, second]);
      expect(registrationRepository.bindings, hasLength(1));
    },
  );

  test('binds again when the SDK registration id changes', () async {
    final pushGateway = _FakePushGateway(registrationId: 'registration-1');
    final registrationRepository = _FakePushRegistrationRepository();
    final container = _createContainer(
      pushGateway: pushGateway,
      hardwareGateway: _NotificationPermissionGateway(PermissionStatus.granted),
      authSession: const AuthSession(isAuthenticated: true, userId: 'user-1'),
      registrationRepository: registrationRepository,
      registrationContext: const _FakeLoginDeviceContextProvider(
        deviceId: 'installation-1',
        platform: 'IOS',
      ),
    );
    addTearDown(container.dispose);

    final service = container.read(pushServiceProvider.notifier);
    await _initializeAndFlush(service);
    pushGateway.registrationId = 'registration-2';
    pushGateway.emit(const PushConnectionChanged(connected: true));
    await _flushMicrotasks();
    await service.retryInitialization();

    expect(registrationRepository.bindings.map((item) => item.registrationId), [
      'registration-1',
      'registration-2',
    ]);
  });

  test('deduplicates a completed bind across push service rebuilds', () async {
    final guard = PushRegistrationSyncGuard();
    var calls = 0;

    final first = await guard.run(
      key: 'user-1\u0000registration-1',
      operation: () async => calls += 1,
    );
    final second = await guard.run(
      key: 'user-1\u0000registration-1',
      operation: () async => calls += 1,
    );

    expect(first, PushRegistrationSyncResult.performed);
    expect(second, PushRegistrationSyncResult.alreadyCompleted);
    expect(calls, 1);
  });

  test(
    'allows the same registration to bind in a later login session',
    () async {
      final guard = PushRegistrationSyncGuard();
      var calls = 0;
      const key = 'user-1\u0000registration-1';

      await guard.run(key: key, operation: () async => calls += 1);
      guard.clearUser('user-1');
      await guard.run(key: key, operation: () async => calls += 1);

      expect(calls, 2);
    },
  );

  test('allows retry after a registration bind failure', () async {
    final guard = PushRegistrationSyncGuard();
    var calls = 0;
    const key = 'user-1\u0000registration-1';

    await expectLater(
      guard.run(
        key: key,
        operation: () async {
          calls += 1;
          throw StateError('bind failed');
        },
      ),
      throwsStateError,
    );
    await guard.run(key: key, operation: () async => calls += 1);

    expect(calls, 2);
  });
}

ProviderContainer _createContainer({
  required PushGateway pushGateway,
  required _NotificationPermissionGateway hardwareGateway,
  PushConfiguration? pushConfiguration,
  AuthSession? authSession,
  PushRegistrationRepository? registrationRepository,
  LoginDeviceContextProvider? registrationContext,
}) {
  return ProviderContainer(
    overrides: [
      pushConfigurationProvider.overrideWithValue(
        pushConfiguration ??
            const PushConfiguration(
              appKey: 'test-app-key',
              channel: 'test',
              iosProduction: false,
            ),
      ),
      pushGatewayProvider.overrideWithValue(pushGateway),
      pushHardwareGatewayProvider.overrideWithValue(hardwareGateway),
      appLoggerProvider.overrideWithValue(const _TestLogger()),
      if (authSession != null)
        authSessionProvider.overrideWith((ref) async => authSession),
      if (registrationRepository != null)
        pushRegistrationRepositoryProvider.overrideWithValue(
          registrationRepository,
        ),
      if (registrationContext != null)
        pushRegistrationContextProvider.overrideWithValue(registrationContext),
    ],
  );
}

Future<void> _initializeAndFlush(PushService service) async {
  await service.initialize();
  await service.retryInitialization();
  await _flushMicrotasks();
}

Future<void> _flushMicrotasks() async {
  for (var index = 0; index < 4; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _NotificationPermissionGateway extends MockHardwareGateway {
  _NotificationPermissionGateway(this.notificationStatus);

  PermissionStatus notificationStatus;
  PermissionStatus requestResult = PermissionStatus.granted;
  Future<PermissionStatus> Function()? requestHandler;
  var requestCalls = 0;

  @override
  Future<PermissionStatus> getNotificationPermission({
    required String requestId,
  }) async {
    return notificationStatus;
  }

  @override
  Future<PermissionStatus> requestNotificationPermission({
    required String requestId,
  }) async {
    requestCalls += 1;
    final handler = requestHandler;
    if (handler != null) return handler();
    notificationStatus = requestResult;
    return requestResult;
  }
}

class _FakePushGateway implements PushGateway {
  _FakePushGateway({this.registrationId});

  final StreamController<PushEvent> _events =
      StreamController<PushEvent>.broadcast();
  var initializeCalls = 0;
  String? registrationId;

  @override
  Stream<PushEvent> get events => _events.stream;

  @override
  Future<void> initialize(PushConfiguration configuration) async {
    initializeCalls += 1;
  }

  @override
  Future<String?> getRegistrationId() async => registrationId;

  void emit(PushEvent event) => _events.add(event);

  @override
  Future<void> dispose() => _events.close();
}

class _FakePushRegistrationRepository implements PushRegistrationRepository {
  final List<PushRegistration> bindings = [];
  final List<String> bindRequestIds = [];
  final List<String> unbindRequestIds = [];
  Completer<void>? bindGate;
  var bindCalls = 0;

  @override
  Future<void> bind({
    required PushRegistration registration,
    required String requestId,
  }) async {
    bindCalls += 1;
    bindRequestIds.add(requestId);
    final gate = bindGate;
    if (gate != null) await gate.future;
    bindings.add(registration);
  }

  @override
  Future<void> unbind({required String requestId}) async {
    unbindRequestIds.add(requestId);
  }
}

class _FakeLoginDeviceContextProvider implements LoginDeviceContextProvider {
  const _FakeLoginDeviceContextProvider({
    required this.deviceId,
    required this.platform,
  });

  final String deviceId;
  final String platform;

  @override
  Future<LoginDeviceContext> read() async => LoginDeviceContext(
    deviceId: deviceId,
    deviceModel: 'Test Device',
    platform: platform,
    appVersion: '1.0.0',
  );
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
