import 'dart:async';

import 'package:flinx/app/flinx_app.dart';
import 'package:flinx/features/add_device/application/add_device_controller.dart';
import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/data/data_sources/account_local_data_source.dart';
import 'package:flinx/features/account/data/dto/account_profile_dto.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/auth_session.dart';
import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/features/home/domain/entities/home_scene.dart';
import 'package:flinx/features/home/presentation/pages/home_page.dart';
import 'package:flinx/features/notification/application/providers.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/platform_bridge/providers.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'requests Android Bluetooth and location permissions after the home first frame',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final gateway = _HomeStartupPermissionGateway();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authSessionProvider.overrideWith(
                (ref) async =>
                    const AuthSession(isAuthenticated: true, userId: 'user-1'),
              ),
              accountLocalDataSourceProvider.overrideWithValue(
                InMemoryAccountLocalDataSource(),
              ),
              hardwareGatewayProvider.overrideWithValue(gateway),
              homeScenesProvider.overrideWith(
                (ref) async => const [
                  HomeScene(id: 1, name: 'Home', doorCount: 0, isDefault: true),
                ],
              ),
              homeDevicesProvider.overrideWith(
                (ref) async => const <DeviceSummary>[],
              ),
              notificationUnreadStateProvider.overrideWith(
                (ref) async => false,
              ),
            ],
            child: const FlinxApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(gateway.requestedPermissions, [
          [PermissionKind.bluetooth],
        ]);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets('shows a badge when unread messages are available', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'user-1'),
          ),
          accountLocalDataSourceProvider.overrideWithValue(
            InMemoryAccountLocalDataSource(),
          ),
          homeScenesProvider.overrideWith(
            (ref) async => const [
              HomeScene(id: 1, name: 'Home', doorCount: 0, isDefault: true),
            ],
          ),
          homeDevicesProvider.overrideWith(
            (ref) async => const <DeviceSummary>[],
          ),
          notificationUnreadStateProvider.overrideWith((ref) async => true),
        ],
        child: const FlinxApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('home-notification-unread-badge')),
      findsOneWidget,
    );
  });

  testWidgets('shows the cached account nickname in the home header', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'user-1'),
          ),
          accountLocalDataSourceProvider.overrideWithValue(
            InMemoryAccountLocalDataSource(
              initialProfile: const AccountProfileDto(
                schemaVersion: AccountProfileDto.currentSchemaVersion,
                userId: 'user-1',
                email: 'alex@example.com',
                nickname: 'Alex',
                avatarUrl: ' ',
                registeredAtIso8601: '',
              ),
            ),
          ),
          homeScenesProvider.overrideWith(
            (ref) async => const [
              HomeScene(id: 1, name: 'Home', doorCount: 0, isDefault: true),
            ],
          ),
          homeDevicesProvider.overrideWith(
            (ref) async => const <DeviceSummary>[],
          ),
          notificationUnreadStateProvider.overrideWith((ref) async => false),
        ],
        child: const FlinxApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hi Alex'), findsOneWidget);
  });

  testWidgets('disconnects when home returns, not after an app resume', (
    tester,
  ) async {
    final tracker = _HomeBleDisconnectTracker();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'user-1'),
          ),
          accountLocalDataSourceProvider.overrideWithValue(
            InMemoryAccountLocalDataSource(),
          ),
          homeScenesProvider.overrideWith(
            (ref) async => const [
              HomeScene(id: 1, name: 'Home', doorCount: 0, isDefault: true),
            ],
          ),
          homeDevicesProvider.overrideWith(
            (ref) async => const <DeviceSummary>[],
          ),
          addDeviceControllerProvider.overrideWith(
            () => _HomeBleDisconnectController(tracker),
          ),
          notificationUnreadStateProvider.overrideWith((ref) async {
            tracker.unreadStateRequestCount += 1;
            return false;
          }),
        ],
        child: const FlinxApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tracker.callCount, 1);
    expect(tracker.unreadStateRequestCount, 1);

    final homeContext = tester.element(find.byType(HomePage));
    unawaited(
      Navigator.of(homeContext).push<void>(
        MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(tracker.callCount, 1);

    Navigator.of(homeContext).pop();
    await tester.pumpAndSettle();

    expect(tracker.callCount, 2);
    expect(tracker.unreadStateRequestCount, 2);
  });

  testWidgets('pull to refresh reloads all home data', (tester) async {
    var sceneRequestCount = 0;
    var deviceRequestCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'user-1'),
          ),
          accountLocalDataSourceProvider.overrideWithValue(
            InMemoryAccountLocalDataSource(),
          ),
          homeScenesProvider.overrideWith((ref) async {
            sceneRequestCount += 1;
            return const [
              HomeScene(id: 1, name: 'Home', doorCount: 0, isDefault: true),
            ];
          }),
          homeDevicesProvider.overrideWith((ref) async {
            deviceRequestCount += 1;
            return const <DeviceSummary>[];
          }),
          addDeviceControllerProvider.overrideWith(
            () => _HomeBleDisconnectController(_HomeBleDisconnectTracker()),
          ),
          notificationUnreadStateProvider.overrideWith((ref) async => false),
        ],
        child: const FlinxApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(sceneRequestCount, 1);
    expect(deviceRequestCount, 1);
    expect(find.byType(EasyRefresh), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 320));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(sceneRequestCount, 2);
    expect(deviceRequestCount, 2);
  });

  testWidgets('does not replace the home content with a loading spinner', (
    tester,
  ) async {
    final scenes = Completer<List<HomeScene>>();
    final devices = Completer<List<DeviceSummary>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'user-1'),
          ),
          accountLocalDataSourceProvider.overrideWithValue(
            InMemoryAccountLocalDataSource(),
          ),
          homeScenesProvider.overrideWith((ref) => scenes.future),
          homeDevicesProvider.overrideWith((ref) => devices.future),
          addDeviceControllerProvider.overrideWith(
            () => _HomeBleDisconnectController(_HomeBleDisconnectTracker()),
          ),
          notificationUnreadStateProvider.overrideWith((ref) async => false),
        ],
        child: const FlinxApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    scenes.complete(const [
      HomeScene(id: 1, name: 'Home', doorCount: 0, isDefault: true),
    ]);
    devices.complete(const <DeviceSummary>[]);
    await tester.pumpAndSettle();
  });

  testWidgets('shows the sharing badge and places the status dot below it', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'user-1'),
          ),
          accountLocalDataSourceProvider.overrideWithValue(
            InMemoryAccountLocalDataSource(),
          ),
          homeScenesProvider.overrideWith(
            (ref) async => const [
              HomeScene(id: 1, name: 'Home', doorCount: 1, isDefault: true),
            ],
          ),
          homeDevicesProvider.overrideWith(
            (ref) async => const [
              DeviceSummary(
                id: 'door-1',
                name: 'Shared garage',
                onlineState: DeviceOnlineState.online,
                bleState: BleConnectionState.connected,
                doorState: DoorState.closed,
                cycleCount: 0,
                remainingLifePercent: 100,
                sceneId: 1,
                shareStatus: 2,
                shareStatusLabel: 'Sharing',
              ),
            ],
          ),
          addDeviceControllerProvider.overrideWith(
            () => _HomeBleDisconnectController(_HomeBleDisconnectTracker()),
          ),
          notificationUnreadStateProvider.overrideWith((ref) async => false),
        ],
        child: const FlinxApp(),
      ),
    );
    await tester.pumpAndSettle();

    final badge = find.byKey(const ValueKey('home-device-sharing-badge'));
    final statusDot = find.byKey(const ValueKey('home-device-status-dot'));

    expect(badge, findsOneWidget);
    expect(statusDot, findsOneWidget);
    expect(
      tester.getTopLeft(statusDot).dy,
      greaterThan(tester.getTopLeft(badge).dy),
    );
  });

  testWidgets('shows only shared-door editing actions for share status 2', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'user-1'),
          ),
          accountLocalDataSourceProvider.overrideWithValue(
            InMemoryAccountLocalDataSource(),
          ),
          homeScenesProvider.overrideWith(
            (ref) async => const [
              HomeScene(id: 1, name: 'Home', doorCount: 1, isDefault: true),
            ],
          ),
          homeDevicesProvider.overrideWith(
            (ref) async => const [
              DeviceSummary(
                id: 'door-1',
                name: 'Shared garage',
                onlineState: DeviceOnlineState.online,
                bleState: BleConnectionState.connected,
                doorState: DoorState.closed,
                cycleCount: 0,
                remainingLifePercent: 100,
                sceneId: 1,
                shareStatus: 2,
              ),
            ],
          ),
          addDeviceControllerProvider.overrideWith(
            () => _HomeBleDisconnectController(_HomeBleDisconnectTracker()),
          ),
          notificationUnreadStateProvider.overrideWith((ref) async => false),
        ],
        child: const FlinxApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Shared garage'));
    await tester.pumpAndSettle();

    expect(find.text('Move Scene'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Delete Device'), findsNothing);
    expect(find.text('Top'), findsNothing);
    expect(find.text('Customize'), findsNothing);
    expect(find.text('Share'), findsNothing);
  });

  testWidgets('shows No Device when sharing a door without a device', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'user-1'),
          ),
          accountLocalDataSourceProvider.overrideWithValue(
            InMemoryAccountLocalDataSource(),
          ),
          homeScenesProvider.overrideWith(
            (ref) async => const [
              HomeScene(id: 1, name: 'Home', doorCount: 1, isDefault: true),
            ],
          ),
          homeDevicesProvider.overrideWith(
            (ref) async => const [
              DeviceSummary(
                id: 'door-1',
                name: 'Garage',
                onlineState: DeviceOnlineState.online,
                bleState: BleConnectionState.connected,
                doorState: DoorState.closed,
                cycleCount: 0,
                remainingLifePercent: 100,
                sceneId: 1,
                hasBoundDevices: false,
              ),
            ],
          ),
          addDeviceControllerProvider.overrideWith(
            () => _HomeBleDisconnectController(_HomeBleDisconnectTracker()),
          ),
          notificationUnreadStateProvider.overrideWith((ref) async => false),
        ],
        child: const FlinxApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Garage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    expect(find.text('No Device'), findsOneWidget);
    expect(find.text('Device editing'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('opens sharing when a door has bound devices', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'user-1'),
          ),
          accountLocalDataSourceProvider.overrideWithValue(
            InMemoryAccountLocalDataSource(),
          ),
          homeScenesProvider.overrideWith(
            (ref) async => const [
              HomeScene(id: 1, name: 'Home', doorCount: 1, isDefault: true),
            ],
          ),
          homeDevicesProvider.overrideWith(
            (ref) async => const [
              DeviceSummary(
                id: '1',
                name: 'Garage',
                onlineState: DeviceOnlineState.online,
                bleState: BleConnectionState.connected,
                doorState: DoorState.closed,
                cycleCount: 0,
                remainingLifePercent: 100,
                sceneId: 1,
                hasBoundDevices: true,
              ),
            ],
          ),
          addDeviceControllerProvider.overrideWith(
            () => _HomeBleDisconnectController(_HomeBleDisconnectTracker()),
          ),
          notificationUnreadStateProvider.overrideWith((ref) async => false),
        ],
        child: const FlinxApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Garage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Device editing'), findsNothing);
  });

  testWidgets('keeps the sharing badge hidden for non-shared doors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'user-1'),
          ),
          accountLocalDataSourceProvider.overrideWithValue(
            InMemoryAccountLocalDataSource(),
          ),
          homeScenesProvider.overrideWith(
            (ref) async => const [
              HomeScene(id: 1, name: 'Home', doorCount: 1, isDefault: true),
            ],
          ),
          homeDevicesProvider.overrideWith(
            (ref) async => const [
              DeviceSummary(
                id: 'door-1',
                name: 'Garage',
                onlineState: DeviceOnlineState.online,
                bleState: BleConnectionState.connected,
                doorState: DoorState.closed,
                cycleCount: 0,
                remainingLifePercent: 100,
                sceneId: 1,
                shareStatus: 1,
              ),
            ],
          ),
          addDeviceControllerProvider.overrideWith(
            () => _HomeBleDisconnectController(_HomeBleDisconnectTracker()),
          ),
          notificationUnreadStateProvider.overrideWith((ref) async => false),
        ],
        child: const FlinxApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('home-device-sharing-badge')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('home-device-status-dot')),
      findsOneWidget,
    );
  });
}

class _HomeBleDisconnectTracker {
  var callCount = 0;
  var unreadStateRequestCount = 0;
}

class _HomeBleDisconnectController extends AddDeviceController {
  _HomeBleDisconnectController(this._tracker);

  final _HomeBleDisconnectTracker _tracker;

  @override
  AddDeviceState build() => AddDeviceState.initial();

  @override
  Future<bool> disconnectConnectedBleDevices() async {
    _tracker.callCount += 1;
    return true;
  }
}

class _HomeStartupPermissionGateway extends MockHardwareGateway {
  final List<List<PermissionKind>> requestedPermissions =
      <List<PermissionKind>>[];

  @override
  Future<PermissionSnapshot> getPermissionSnapshot({
    required String requestId,
  }) async {
    return const PermissionSnapshot(
      bluetoothStatus: PermissionStatus.denied,
      cameraStatus: PermissionStatus.granted,
      locationStatus: PermissionStatus.denied,
      microphoneStatus: PermissionStatus.granted,
      storageStatus: PermissionStatus.granted,
      localNetworkGranted: true,
      notificationGranted: true,
    );
  }

  @override
  Future<PermissionSnapshot> requestPermissions({
    required String requestId,
    required List<PermissionKind> permissions,
  }) async {
    requestedPermissions.add(List<PermissionKind>.of(permissions));
    return getPermissionSnapshot(requestId: requestId);
  }
}
