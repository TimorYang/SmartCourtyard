import 'dart:async';
import 'dart:typed_data';

import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/features/add_device/domain/entities/onboarding_device_key.dart';
import 'package:flinx/features/add_device/domain/entities/onboarded_force_door.dart';
import 'package:flinx/features/add_device/domain/repositories/add_device_onboarding_repository.dart';
import 'package:flinx/features/add_device/domain/use_cases/fetch_onboarding_device_key_use_case.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/domain/entities/door_detail.dart';
import 'package:flinx/features/device_control/domain/entities/door_device.dart';
import 'package:flinx/features/device_control/domain/entities/remote_door_command.dart';
import 'package:flinx/features/device_control/domain/repositories/door_detail_repository.dart';
import 'package:flinx/features/device_control/domain/repositories/remote_door_command_repository.dart';
import 'package:flinx/features/device_control/presentation/pages/device_command_page.dart';
import 'package:flinx/features/device_control/presentation/pages/device_settings_page.dart';
import 'package:flinx/features/device_control/presentation/pages/already_added_devices_page.dart';
import 'package:flinx/features/records/application/providers.dart';
import 'package:flinx/features/records/domain/entities/operation_record_page_result.dart';
import 'package:flinx/features/records/domain/repositories/operation_record_repository.dart';
import 'package:flinx/features/settings/application/providers.dart';
import 'package:flinx/features/settings/domain/entities/device_capability.dart';
import 'package:flinx/features/settings/domain/entities/door_setting_snapshot.dart';
import 'package:flinx/features/settings/domain/repositories/device_capability_repository.dart';
import 'package:flinx/features/settings/domain/repositories/door_settings_repository.dart';
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
    expect(find.text('More settings'), findsOneWidget);
    expect(find.text('60 cm'), findsOneWidget);
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
    expect(find.text('Open command sent (0x1001).'), findsOneWidget);

    await tester.tap(find.byTooltip('Stop'));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.stop);
    expect(find.text('Stop command sent (0x1003).'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.close);
    expect(find.text('Close command sent (0x1002).'), findsOneWidget);
  });

  testWidgets('updates the door frame and state from attribute reports', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();
    await _pumpDevicePage(
      tester,
      gateway,
      repository: const _FakeDoorDetailRepository(
        doorType: 0,
        positionPercent: 0,
      ),
    );

    expect(_doorHeroAsset(tester), endsWith('garage_door_01.png'));

    gateway.emitDeviceAttributeSnapshot(
      DeviceAttributeSnapshot(
        deviceId: 'mock-ble-device',
        sequence: 1,
        timestampMillis: 1,
        origin: DeviceAttributeReportOrigin.activeReport,
        attributes: [
          DeviceAttribute(id: 0x2715, value: Uint8List.fromList([0x03])),
          DeviceAttribute(id: 0x271C, value: Uint8List.fromList([50])),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Opening · 50%'), findsOneWidget);

    expect(_doorHeroAsset(tester), endsWith('garage_door_11.png'));
  });

  testWidgets('uses swing gate frames for the reported position', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();
    await _pumpDevicePage(
      tester,
      gateway,
      repository: const _FakeDoorDetailRepository(
        doorType: 3,
        positionPercent: 100,
      ),
    );

    expect(_doorHeroAsset(tester), endsWith('swing_door_20.png'));
  });

  testWidgets('quick actions send light, partial open, and open settings', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(tester, gateway);

    await tester.tap(find.byKey(const ValueKey<String>('led-switch')));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.lightOn);
    expect(find.text('Turn LED on command sent (0x1005).'), findsOneWidget);

    final partialOpenAction = find.byKey(
      const ValueKey<String>('partial-open-action'),
    );
    await tester.ensureVisible(partialOpenAction);
    await tester.drag(find.byType(ListView).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(partialOpenAction);
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.partialOpen);
    expect(find.text('Partial open command sent (0x1004).'), findsOneWidget);

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
    expect(
      tester
          .widget<DeviceSettingsPage>(find.byType(DeviceSettingsPage))
          .bleName,
      'Garage door',
    );
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

  testWidgets('disables controls whose capabilities are absent', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(
      tester,
      gateway,
      repository: const _FakeDoorDetailRepository(
        capabilities: ['DOOR_CONTROL'],
      ),
    );

    expect(
      tester
          .widget<FlinxSwitch>(find.byKey(const ValueKey<String>('led-switch')))
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<FlinxSwitch>(
            find.byKey(const ValueKey<String>('auto-close-switch')),
          )
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<FlinxSwitch>(
            find.byKey(const ValueKey<String>('open-reminder-switch')),
          )
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<InkWell>(
            find.descendant(
              of: find.byKey(const ValueKey<String>('partial-open-action')),
              matching: find.byType(InkWell),
            ),
          )
          .onTap,
      isNull,
    );

    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();

    expect(gateway.commands, [DoorCommand.open]);
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
    expect(
      find.byKey(
        const ValueKey<String>('already-added-device-card-Garage door'),
      ),
      findsOneWidget,
    );
    expect(find.text('Garage door'), findsOneWidget);
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
    expect(find.text('智能开门器'), findsOneWidget);
    expect(find.text('Garage door'), findsOneWidget);
  });

  testWidgets('unbinds an already added device and refreshes the list', (
    tester,
  ) async {
    final repository = _UnbindDoorDetailRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [doorDetailRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AlreadyAddedDevicesPage(doorId: '12'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('already-added-delete-action-Garage door'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('already-added-disconnect-confirm-action'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.unboundDeviceIds, ['3']);
    expect(find.text('No connected devices'), findsOneWidget);
  });

  testWidgets('shows an error message when device unbinding fails', (
    tester,
  ) async {
    final repository = _UnbindDoorDetailRepository(shouldFail: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [doorDetailRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AlreadyAddedDevicesPage(doorId: '12'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('already-added-delete-action-Garage door'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('already-added-disconnect-confirm-action'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to remove device. Please try again.'),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('already-added-device-card-Garage door'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows pending state while a command is in progress', (
    tester,
  ) async {
    final gateway = _PendingCommandGateway();

    await _pumpDevicePage(tester, gateway);

    await tester.tap(find.byTooltip('Open'));
    await tester.pump();

    expect(find.text('Sending Open command (0x1001)...'), findsOneWidget);
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

    expect(find.text('Open command sent (0x1001).'), findsOneWidget);
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

  testWidgets('cleans all managed BLE connections when page is removed', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(tester, gateway);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(gateway.disconnectAllCount, greaterThanOrEqualTo(1));
  });

  testWidgets(
    'uses remote control without BLE and renders polled door position',
    (tester) async {
      final repository = _SequencedDoorDetailRepository();
      final remoteRepository = _SuccessfulRemoteDoorCommandRepository();
      await _pumpDevicePage(
        tester,
        _DisconnectedHardwareGateway(),
        repository: repository,
        remoteRepository: remoteRepository,
        remotePollInterval: Duration.zero,
      );

      await tester.tap(find.byTooltip('Open'));
      await tester.pumpAndSettle();

      expect(remoteRepository.actions, [RemoteDoorCommandAction.open]);
      expect(find.text('Open command sent (0x1001).'), findsOneWidget);
      expect(find.text('Opened · 100%'), findsOneWidget);
      expect(_doorHeroAsset(tester), endsWith('garage_door_20.png'));
    },
  );
}

Widget _buildPage(
  MockHardwareGateway gateway, {
  DoorDetailRepository repository = const _FakeDoorDetailRepository(),
  RemoteDoorCommandRepository? remoteRepository,
  Duration remotePollInterval = const Duration(seconds: 1),
}) {
  return ProviderScope(
    overrides: [
      deviceCommandHardwareGatewayProvider.overrideWithValue(gateway),
      doorDetailRepositoryProvider.overrideWithValue(repository),
      if (remoteRepository != null)
        remoteDoorCommandRepositoryProvider.overrideWithValue(remoteRepository),
      deviceCommandRemotePollIntervalProvider.overrideWithValue(
        remotePollInterval,
      ),
      fetchOnboardingDeviceKeyUseCaseProvider.overrideWithValue(
        const _FakeFetchOnboardingDeviceKeyUseCase(),
      ),
      operationRecordRepositoryProvider.overrideWithValue(
        const _EmptyOperationRecordRepository(),
      ),
      deviceCapabilityRepositoryProvider.overrideWithValue(
        const _SettingsDeviceCapabilityRepository(),
      ),
      doorSettingsRepositoryProvider.overrideWithValue(
        const _EmptyDoorSettingsRepository(),
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
              doorId: state.uri.queryParameters['doorId'] ?? '',
              deviceId: state.uri.queryParameters['deviceId'] ?? '',
              bleName: state.uri.queryParameters['bleName'] ?? '',
              bleDeviceId: state.uri.queryParameters['bleDeviceId'] ?? '',
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

class _SettingsDeviceCapabilityRepository
    implements DeviceCapabilityRepository {
  const _SettingsDeviceCapabilityRepository();

  @override
  Future<List<DeviceCapability>> fetchCapabilities({
    required String deviceId,
    required String requestId,
  }) async => const [
    DeviceCapability(
      code: DeviceCapabilityCode.transmitterPairing,
      label: 'Transmitter management',
    ),
  ];
}

class _EmptyDoorSettingsRepository implements DoorSettingsRepository {
  const _EmptyDoorSettingsRepository();

  @override
  Future<List<DoorSettingSnapshot>> fetchSettings({
    required String doorId,
    required String requestId,
  }) async => const [];
}

Future<void> _pumpDevicePage(
  WidgetTester tester,
  MockHardwareGateway gateway, {
  DoorDetailRepository repository = const _FakeDoorDetailRepository(),
  RemoteDoorCommandRepository? remoteRepository,
  Duration remotePollInterval = const Duration(seconds: 1),
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    _buildPage(
      gateway,
      repository: repository,
      remoteRepository: remoteRepository,
      remotePollInterval: remotePollInterval,
    ),
  );
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

String _doorHeroAsset(WidgetTester tester) {
  final frame = find.byKey(const ValueKey<String>('door-hero-frame'));
  final image = tester.widget<Image>(
    find.descendant(of: frame, matching: find.byType(Image)),
  );
  return (image.image as AssetImage).assetName;
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
  int disconnectAllCount = 0;

  @override
  Future<List<BleConnectionEvent>> disconnectAllManagedBleDevices({
    required String requestId,
  }) async {
    disconnectAllCount += 1;
    return super.disconnectAllManagedBleDevices(requestId: requestId);
  }

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

class _DisconnectedHardwareGateway extends MockHardwareGateway {}

class _SuccessfulRemoteDoorCommandRepository
    implements RemoteDoorCommandRepository {
  final List<RemoteDoorCommandAction> actions = <RemoteDoorCommandAction>[];

  @override
  Future<RemoteDoorCommand> submitCommand({
    required String doorId,
    required RemoteDoorCommandAction action,
    required String requestId,
  }) async {
    actions.add(action);
    return RemoteDoorCommand(
      commandId: 'command-1',
      doorId: doorId,
      action: action,
      status: RemoteDoorCommandStatus.succeeded,
    );
  }

  @override
  Future<RemoteDoorCommand> fetchCommand({
    required String doorId,
    required String commandId,
    required String requestId,
  }) {
    throw StateError('A terminal submit response must not be polled.');
  }
}

class _SequencedDoorDetailRepository implements DoorDetailRepository {
  final List<DoorDetail> _details = <DoorDetail>[
    const DoorDetail(
      id: '12',
      name: 'Garage door',
      doorState: DoorState.closed,
      doorStateLabel: 'Closed',
      positionPercent: 0,
      operatedCycles: 0,
      remainingCycles: 0,
    ),
    const DoorDetail(
      id: '12',
      name: 'Garage door',
      doorState: DoorState.opening,
      doorStateLabel: 'Opening',
      positionPercent: 40,
      operatedCycles: 0,
      remainingCycles: 0,
    ),
    const DoorDetail(
      id: '12',
      name: 'Garage door',
      doorState: DoorState.open,
      doorStateLabel: 'Open',
      positionPercent: 100,
      operatedCycles: 0,
      remainingCycles: 0,
    ),
  ];

  DoorDetail? _lastDetail;

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) async {
    if (_details.isNotEmpty) {
      _lastDetail = _details.removeAt(0);
    }
    return _lastDetail!;
  }

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) async => const [
    DoorDevice(
      deviceId: '3',
      sn: 'remote-only',
      deviceType: 'opener',
      capabilities: ['DOOR_CONTROL', 'LED_CONTROL'],
    ),
  ];

  @override
  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) {
    throw UnimplementedError();
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
    String? doorId,
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
  const _FakeDoorDetailRepository({
    this.capabilities = const [
      'DOOR_CONTROL',
      'PARTIAL_OPEN',
      'LED_CONTROL',
      'AUTO_CLOSE',
      'DOOR_OPEN_REMINDER',
    ],
    this.doorType,
    this.positionPercent,
  });

  final List<String> capabilities;
  final int? doorType;
  final double? positionPercent;

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) async {
    return DoorDetail(
      id: '12',
      name: 'Garage door',
      doorState: DoorState.closed,
      doorStateLabel: 'Closed',
      doorType: doorType,
      positionPercent: positionPercent,
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
  }) async => [
    DoorDevice(
      deviceId: '3',
      sn: 'opener_B8F86211A9DC',
      deviceType: 'opener',
      bleName: 'Garage door',
      bleConnectionStatus: 1,
      wifiConnectionStatus: 1,
      capabilities: capabilities,
    ),
  ];

  @override
  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) => throw UnimplementedError();
}

class _UnbindDoorDetailRepository extends _FakeDoorDetailRepository {
  _UnbindDoorDetailRepository({this.shouldFail = false});

  final bool shouldFail;
  List<DoorDevice> devices = <DoorDevice>[
    const DoorDevice(
      deviceId: '3',
      sn: 'opener_B8F86211A9DC',
      deviceType: 'opener',
      bleName: 'Garage door',
    ),
  ];
  final List<String> unboundDeviceIds = <String>[];

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) async => devices;

  @override
  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) async {
    unboundDeviceIds.add(deviceId);
    if (shouldFail) {
      throw StateError('unbind failure');
    }
    devices = const <DoorDevice>[];
  }
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
