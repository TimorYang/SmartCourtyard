import 'dart:async';

import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/features/add_device/domain/entities/onboarding_device_key.dart';
import 'package:flinx/features/add_device/domain/entities/onboarded_force_door.dart';
import 'package:flinx/features/add_device/domain/repositories/add_device_onboarding_repository.dart';
import 'package:flinx/features/add_device/domain/use_cases/fetch_onboarding_device_key_use_case.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/domain/entities/door_detail.dart';
import 'package:flinx/features/device_control/domain/entities/door_device.dart';
import 'package:flinx/features/device_control/domain/repositories/door_detail_repository.dart';
import 'package:flinx/features/device_control/presentation/pages/device_command_page.dart';
import 'package:flinx/features/device_control/presentation/pages/device_settings_page.dart';
import 'package:flinx/features/device_control/presentation/pages/already_added_devices_page.dart';
import 'package:flinx/features/records/application/providers.dart';
import 'package:flinx/features/records/domain/entities/operation_record_page_result.dart';
import 'package:flinx/features/records/domain/repositories/operation_record_repository.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flinx/shared/widgets/flinx_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders garage door controls and sends primary commands', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(tester, gateway);

    expect(find.text('Garage door'), findsOneWidget);
    expect(find.text('Operated cycles'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('4567'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('LED'), findsOneWidget);
    expect(find.text('Auto close'), findsOneWidget);
    expect(find.text('Open reminder'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
    expect(find.text('Partial open'), findsOneWidget);
    expect(find.text('More setting'), findsOneWidget);
    expect(find.text('60cm'), findsOneWidget);
    expect(
      tester
          .widget<FlinxSwitch>(find.byKey(const ValueKey<String>('led-switch')))
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<FlinxSwitch>(
            find.byKey(const ValueKey<String>('auto-close-switch')),
          )
          .value,
      isTrue,
    );

    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.open);
    expect(gateway.deviceIds.last, 'mock-ble-device');
    expect(gateway.authenticatedDeviceIds, ['mock-ble-device']);
    expect(find.text('开门指令已发送（0x1001）。'), findsOneWidget);

    await tester.tap(find.byTooltip('Stop'));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.stop);
    expect(find.text('暂停指令已发送（0x1003）。'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.close);
    expect(find.text('关门指令已发送（0x1002）。'), findsOneWidget);
  });

  testWidgets('quick actions send light, partial open, and open settings', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(tester, gateway);

    await tester.tap(find.byKey(const ValueKey<String>('led-switch')));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.lightOn);
    expect(find.text('开灯指令已发送（0x1005）。'), findsOneWidget);

    final partialOpenAction = find.byKey(
      const ValueKey<String>('partial-open-action'),
    );
    await tester.ensureVisible(partialOpenAction);
    await tester.drag(find.byType(ListView).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(partialOpenAction);
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.partialOpen);
    expect(find.text('半开门指令已发送（0x1004）。'), findsOneWidget);

    final moreSettingsAction = find.byKey(
      const ValueKey<String>('more-settings-action'),
    );
    await tester.ensureVisible(moreSettingsAction);
    await tester.drag(find.byType(ListView).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(moreSettingsAction);
    await tester.pumpAndSettle();

    expect(gateway.queryCount, 0);
    expect(find.text('Setting'), findsOneWidget);
    expect(find.text('Transmitter management'), findsOneWidget);
  });

  testWidgets('toggles the open reminder quick action', (tester) async {
    await _pumpDevicePage(tester, _RecordingHardwareGateway());

    final reminderSwitch = find.byKey(
      const ValueKey<String>('open-reminder-switch'),
    );
    expect(tester.widget<FlinxSwitch>(reminderSwitch).value, isTrue);

    await tester.tap(reminderSwitch);
    await tester.pump();

    expect(tester.widget<FlinxSwitch>(reminderSwitch).value, isFalse);
  });

  testWidgets('uses door-device list to highlight the matching fixed card', (
    tester,
  ) async {
    await _pumpDevicePage(tester, _RecordingHardwareGateway());

    expect(
      _connectionDeviceAsset(tester, 'opener'),
      'assets/icons/device_control/device_command_opener_active.png',
    );
    expect(
      _connectionDeviceAsset(tester, 'dongle'),
      'assets/icons/device_control/device_command_dongle_inactive.png',
    );
    expect(
      _connectionDeviceAsset(tester, 'fbox'),
      'assets/icons/device_control/device_command_fbox_inactive.png',
    );
    expect(
      _connectionDeviceAsset(tester, 'video'),
      'assets/icons/device_control/device_command_video_inactive.png',
    );
    expect(
      _connectionDeviceAsset(tester, 'evo'),
      'assets/icons/device_control/device_command_evo_inactive.png',
    );
    expect(_connectionGroupAssets(tester, 'opener'), [
      'assets/icons/device_control/device_command_opener_active.png',
      'assets/icons/device_control/device_command_bluetooth_active_placeholder.png',
      'assets/icons/device_control/device_command_wifi_inactive_placeholder.png',
    ]);
    expect(_connectionGroupAssets(tester, 'video'), [
      'assets/icons/device_control/device_command_video_inactive.png',
      'assets/icons/device_control/device_command_wifi_inactive_placeholder.png',
    ]);
    expect(_hasConnectionBorder(tester, 'opener'), isTrue);
    expect(_hasConnectionBorder(tester, 'video'), isFalse);
    expect(_connectionTap(tester, 'opener'), isNotNull);
    expect(_connectionTap(tester, 'dongle'), isNull);
    expect(_connectionTap(tester, 'video'), isNull);
  });

  testWidgets('opens the already added devices page from the more action', (
    tester,
  ) async {
    await _pumpDevicePage(tester, _RecordingHardwareGateway());

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();

    expect(find.text('Already Added'), findsOneWidget);
    expect(
      find.text('The following devices have been connected'),
      findsOneWidget,
    );
    expect(find.text('No connected devices'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('already-added-add-action')),
      findsOneWidget,
    );

    await tester.tap(
      find.ancestor(
        of: find.byType(BackButtonIcon),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Garage door'), findsOneWidget);
  });

  testWidgets('renders already added devices copy in Chinese', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doorDetailRepositoryProvider.overrideWithValue(
            const _FakeDoorDetailRepository(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AlreadyAddedDevicesPage(doorId: '12'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('已添加'), findsOneWidget);
    expect(find.text('以下设备已连接'), findsOneWidget);
    expect(find.text('暂无已连接设备'), findsOneWidget);
  });

  testWidgets('shows pending state while a command is in progress', (
    tester,
  ) async {
    final gateway = _PendingCommandGateway();

    await _pumpDevicePage(tester, gateway);

    await tester.tap(find.byTooltip('Open'));
    await tester.pump();

    expect(find.text('正在发送开门指令（0x1001）...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    for (final button in tester.widgetList<IconButton>(
      find.byType(IconButton),
    )) {
      if (button.tooltip == 'Stop' || button.tooltip == 'Close') {
        expect(button.onPressed, isNull);
      }
    }

    gateway.complete(DoorCommand.open);
    await tester.pumpAndSettle();

    expect(find.text('开门指令已发送（0x1001）。'), findsOneWidget);
  });

  testWidgets('switches between records and command tabs', (tester) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(tester, gateway);

    expect(find.text('Closed'), findsOneWidget);

    await tester.tap(find.byTooltip('Operation records'));
    await tester.pumpAndSettle();

    expect(find.text('Operation Record'), findsOneWidget);

    await tester.tap(find.byTooltip('Device command'));
    await tester.pumpAndSettle();

    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Garage door'), findsOneWidget);
  });

  testWidgets('renders on a compact screen without overflow', (tester) async {
    final gateway = _RecordingHardwareGateway();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildPage(gateway));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Security center'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Widget _buildPage(MockHardwareGateway gateway) {
  return ProviderScope(
    overrides: [
      deviceCommandHardwareGatewayProvider.overrideWithValue(gateway),
      doorDetailRepositoryProvider.overrideWithValue(
        const _FakeDoorDetailRepository(),
      ),
      fetchOnboardingDeviceKeyUseCaseProvider.overrideWithValue(
        const _FakeFetchOnboardingDeviceKeyUseCase(),
      ),
      operationRecordRepositoryProvider.overrideWithValue(
        const _EmptyOperationRecordRepository(),
      ),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        initialLocation:
            '${DeviceCommandPage.routePath}?doorId=12&deviceId=mock-device',
        routes: [
          GoRoute(
            path: DeviceCommandPage.routePath,
            builder: (context, state) => DeviceCommandPage(
              doorId: state.uri.queryParameters['doorId'] ?? '',
              deviceId: state.uri.queryParameters['deviceId'] ?? '',
            ),
          ),
          GoRoute(
            path: DeviceSettingsPage.routePath,
            builder: (context, state) => DeviceSettingsPage(
              deviceId: state.uri.queryParameters['deviceId'] ?? '',
            ),
          ),
          GoRoute(
            path: AlreadyAddedDevicesPage.routePath,
            builder: (context, state) => AlreadyAddedDevicesPage(
              doorId: state.uri.queryParameters['doorId'] ?? '',
              deviceId: state.uri.queryParameters['deviceId'] ?? '',
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _pumpDevicePage(
  WidgetTester tester,
  MockHardwareGateway gateway,
) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_buildPage(gateway));
  await tester.pumpAndSettle();
}

String _connectionDeviceAsset(WidgetTester tester, String deviceType) {
  return _connectionGroupAssets(tester, deviceType).first;
}

List<String> _connectionGroupAssets(WidgetTester tester, String deviceType) {
  final group = find.byKey(ValueKey<String>('connection-device-$deviceType'));
  return tester
      .widgetList<Image>(
        find.descendant(of: group, matching: find.byType(Image)),
      )
      .map((image) => (image.image as AssetImage).assetName)
      .toList();
}

bool _hasConnectionBorder(WidgetTester tester, String deviceType) {
  final group = find.byKey(ValueKey<String>('connection-device-$deviceType'));
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: group, matching: find.byType(DecoratedBox)),
  );
  return (box.decoration as BoxDecoration).border != null;
}

GestureTapCallback? _connectionTap(WidgetTester tester, String deviceType) {
  final group = find.byKey(ValueKey<String>('connection-device-$deviceType'));
  return tester
      .widget<GestureDetector>(
        find.descendant(of: group, matching: find.byType(GestureDetector)),
      )
      .onTap;
}

class _RecordingHardwareGateway extends MockHardwareGateway {
  final List<DoorCommand> commands = <DoorCommand>[];
  final List<String> deviceIds = <String>[];
  int queryCount = 0;
  final List<String> authenticatedDeviceIds = <String>[];

  @override
  Future<BleAuthenticationResult> authenticateBleDevice({
    required String requestId,
    required String deviceId,
    required String token,
    required String aesKey,
    required String aesKeyVersion,
  }) async {
    authenticatedDeviceIds.add(deviceId);
    return super.authenticateBleDevice(
      requestId: requestId,
      deviceId: deviceId,
      token: token,
      aesKey: aesKey,
      aesKeyVersion: aesKeyVersion,
    );
  }

  @override
  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  }) async {
    commands.add(command);
    deviceIds.add(deviceId);
    return super.sendDoorCommand(
      requestId: requestId,
      deviceId: deviceId,
      command: command,
    );
  }

  @override
  Future<RemoteControlListResult> queryRemotes({
    required String requestId,
    required String deviceId,
  }) async {
    queryCount += 1;
    return super.queryRemotes(requestId: requestId, deviceId: deviceId);
  }
}

class _FakeFetchOnboardingDeviceKeyUseCase
    extends FetchOnboardingDeviceKeyUseCase {
  const _FakeFetchOnboardingDeviceKeyUseCase()
    : super(repository: const _UnusedDeviceKeyRepository());

  @override
  Future<OnboardingDeviceKey> call({
    required String sn,
    required String requestId,
  }) async {
    return OnboardingDeviceKey(
      sn: sn,
      aesKey: '0123456789abcdef0123456789abcdef',
      aesKeyVersion: 'test',
    );
  }
}

class _UnusedDeviceKeyRepository implements AddDeviceOnboardingRepository {
  const _UnusedDeviceKeyRepository();

  @override
  Future<void> validateBindingStatus({
    required String sn,
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<OnboardedForceDoor> addForceDoor({
    required String sn,
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<OnboardingDeviceKey> fetchDeviceKey({
    required String sn,
    required String requestId,
  }) {
    throw UnimplementedError();
  }
}

class _FakeDoorDetailRepository implements DoorDetailRepository {
  const _FakeDoorDetailRepository();

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) async {
    return const DoorDetail(
      id: '12',
      name: 'Garage door',
      doorState: DoorState.closed,
      doorStateLabel: 'Closed',
      operatedCycles: 123,
      remainingCycles: 4567,
      ledStatus: 1,
      autoCloseEnabled: true,
      openReminderEnabled: true,
      partialOpenValue: 60,
    );
  }

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) async => const [
    DoorDevice(
      deviceId: '3',
      sn: 'opener_B8F86211A9DC',
      deviceType: 'opener',
      bleName: 'Garage door',
      bleConnectionStatus: 1,
      wifiConnectionStatus: 1,
    ),
  ];
}

class _EmptyOperationRecordRepository implements OperationRecordRepository {
  const _EmptyOperationRecordRepository();

  @override
  Future<OperationRecordPageResult> fetchOperationRecords({
    required String doorId,
    required int page,
    required int pageSize,
    required String requestId,
  }) async => OperationRecordPageResult(
    records: const [],
    currentPage: page,
    pageSize: pageSize,
    total: 0,
    hasMore: false,
  );
}

class _PendingCommandGateway extends MockHardwareGateway {
  final Completer<CommandResult> _commandCompleter = Completer<CommandResult>();

  @override
  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  }) {
    return _commandCompleter.future;
  }

  void complete(DoorCommand command) {
    _commandCompleter.complete(
      CommandResult(
        requestId: 'pending-command',
        deviceId: 'mock-device',
        command: command,
        accepted: true,
      ),
    );
  }
}
