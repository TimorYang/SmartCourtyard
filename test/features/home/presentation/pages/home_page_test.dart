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
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
        ],
        child: const FlinxApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hi Alex'), findsOneWidget);
  });

  testWidgets('checks and disconnects BLE whenever home becomes visible', (
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
        ],
        child: const FlinxApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tracker.callCount, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(tracker.callCount, 2);
  });

  testWidgets('pull to refresh reloads devices without reloading home scenes', (
    tester,
  ) async {
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
        ],
        child: const FlinxApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(sceneRequestCount, 1);
    expect(deviceRequestCount, 1);
    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 320));
    await tester.pumpAndSettle();

    expect(sceneRequestCount, 1);
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
}

class _HomeBleDisconnectTracker {
  var callCount = 0;
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
