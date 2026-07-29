import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/managed_login_device.dart';
import 'package:flinx/features/account/domain/repositories/managed_devices_repository.dart';
import 'package:flinx/features/account/presentation/pages/manage_devices_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester,
    _FakeManagedDevicesRepository repo,
  ) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [managedDevicesRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ManageDevicesPage(),
        ),
      ),
    );
  }

  testWidgets('loads devices from the repository without an edit action', (
    tester,
  ) async {
    await pumpPage(tester, _FakeManagedDevicesRepository(_devices));
    await tester.pumpAndSettle();

    expect(find.text('iPhone 16 Pro'), findsOneWidget);
    expect(find.text('Pixel 9'), findsOneWidget);
    expect(find.bySemanticsLabel('Edit signed-in devices'), findsNothing);
  });

  testWidgets('reloads devices whenever the page is entered again', (
    tester,
  ) async {
    final repository = _FakeManagedDevicesRepository(_devices);
    var isPageVisible = true;
    late void Function(bool visible) setPageVisible;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          managedDevicesRepositoryProvider.overrideWithValue(repository),
        ],
        child: StatefulBuilder(
          builder: (context, setState) {
            setPageVisible = (visible) {
              setState(() => isPageVisible = visible);
            };
            return MaterialApp(
              theme: AppTheme.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: isPageVisible
                  ? const ManageDevicesPage()
                  : const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.fetchCount, 1);

    setPageVisible(false);
    await tester.pumpAndSettle();
    setPageVisible(true);
    await tester.pumpAndSettle();

    expect(repository.fetchCount, 2);
  });

  testWidgets('opens and cancels the managed device removal confirmation', (
    tester,
  ) async {
    await pumpPage(tester, _FakeManagedDevicesRepository(_devices));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ManageDevicesKeys.logoutButton('2')));
    await tester.pumpAndSettle();

    expect(find.byKey(ManageDevicesKeys.removeDialog), findsOneWidget);
    await tester.tap(find.byKey(ManageDevicesKeys.removeCancelButton));
    await tester.pumpAndSettle();

    expect(find.byKey(ManageDevicesKeys.removeDialog), findsNothing);
    expect(find.byKey(ManageDevicesKeys.deviceCard('1')), findsOneWidget);
    expect(find.byKey(ManageDevicesKeys.deviceCard('2')), findsOneWidget);
  });

  testWidgets('removes only the confirmed managed device', (tester) async {
    final repository = _FakeManagedDevicesRepository(_devices);
    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ManageDevicesKeys.logoutButton('2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ManageDevicesKeys.removeConfirmButton));
    await tester.pumpAndSettle();

    expect(repository.removedSessionIds, ['2']);
    expect(find.byKey(ManageDevicesKeys.deviceCard('1')), findsOneWidget);
    expect(find.byKey(ManageDevicesKeys.deviceCard('2')), findsNothing);
  });
}

const _devices = [
  ManagedLoginDevice(
    sessionId: '1',
    deviceModel: 'iPhone 16 Pro',
    platform: ManagedLoginDevicePlatform.ios,
    lastLoginTime: null,
    currentDevice: true,
  ),
  ManagedLoginDevice(
    sessionId: '2',
    deviceModel: 'Pixel 9',
    platform: ManagedLoginDevicePlatform.android,
    lastLoginTime: null,
    currentDevice: false,
  ),
];

class _FakeManagedDevicesRepository implements ManagedDevicesRepository {
  _FakeManagedDevicesRepository(List<ManagedLoginDevice> devices)
    : _devices = List.of(devices);

  final List<ManagedLoginDevice> _devices;
  final removedSessionIds = <String>[];
  var fetchCount = 0;

  @override
  Future<List<ManagedLoginDevice>> fetchLoginDevices({
    required String requestId,
  }) async {
    fetchCount += 1;
    return List.of(_devices);
  }

  @override
  Future<void> removeLoginDevice({
    required String sessionId,
    required String requestId,
  }) async {
    removedSessionIds.add(sessionId);
    _devices.removeWhere((device) => device.sessionId == sessionId);
  }
}
