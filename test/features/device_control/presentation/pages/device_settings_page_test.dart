import 'dart:typed_data';

import 'package:flinx/features/device_control/presentation/pages/device_settings_page.dart';
import 'package:flinx/features/device_control/presentation/widgets/device_setting_options_sheet.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/domain/entities/about_device_info.dart';
import 'package:flinx/features/device_control/domain/entities/door_detail.dart';
import 'package:flinx/features/device_control/domain/entities/door_device.dart';
import 'package:flinx/features/device_control/domain/repositories/door_detail_repository.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders queried raw device setting values', (tester) async {
    await _pumpSettingsRouter(tester);

    expect(find.text('Setting'), findsOneWidget);
    expect(find.text('LED off delay'), findsOneWidget);
    expect(find.text('0x05 (5)'), findsNWidgets(2));
    expect(find.text('Partial open'), findsOneWidget);
    expect(find.text('0x07 (7)'), findsOneWidget);
    expect(find.text('Auto close'), findsOneWidget);
    expect(find.text('0x00 (0)'), findsOneWidget);
    expect(find.text('Force margin'), findsOneWidget);
  });

  testWidgets('reads 0x2725 but always writes the selected value to 0x2712', (
    tester,
  ) async {
    final gateway = MockHardwareGateway(
      autoCloseAttributeId: 0x2725,
      autoCloseValue: 75,
    );
    await _pumpSettingsRouter(
      tester,
      gateway: gateway,
      capabilityDefinitions: const [
        DeviceCapability(
          code: DeviceCapabilityCode.autoClose,
          label: 'Auto close',
          unit: 's',
          options: [
            DeviceCapabilityOption(value: 15, label: '15'),
            DeviceCapabilityOption(value: 30, label: '30'),
            DeviceCapabilityOption(value: 75, label: '75'),
            DeviceCapabilityOption(value: 90, label: '90'),
          ],
        ),
      ],
    );

    expect(find.text('75 s'), findsOneWidget);
    await tester.tap(find.text('Auto close'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DeviceCapabilityOptionsSheet>(
            find.byType(DeviceCapabilityOptionsSheet),
          )
          .initialValue,
      75,
    );
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -50));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('90 s'), findsOneWidget);
    final snapshot = await gateway.queryDeviceAttributes(
      requestId: 'verify-settings-page-2725',
      deviceId: 'mock-device',
    );
    final attribute2712 = snapshot.attributes.singleWhere(
      (value) => value.id == 0x2712,
    );
    final attribute2725 = snapshot.attributes.singleWhere(
      (value) => value.id == 0x2725,
    );
    expect(attribute2712.value, Uint8List.fromList(<int>[0x5A]));
    expect(attribute2725.value, Uint8List.fromList(<int>[0x00, 0x4B]));
  });

  testWidgets('uses the server current value as the initial option', (
    tester,
  ) async {
    final gateway = MockHardwareGateway(
      autoCloseAttributeId: 0x2725,
      autoCloseValue: 75,
    );
    await _pumpSettingsRouter(
      tester,
      gateway: gateway,
      capabilityDefinitions: const [
        DeviceCapability(
          code: DeviceCapabilityCode.autoClose,
          label: 'Auto close',
          unit: 's',
          options: [
            DeviceCapabilityOption(value: 15, label: '15'),
            DeviceCapabilityOption(value: 30, label: '30'),
            DeviceCapabilityOption(value: 75, label: '75'),
          ],
        ),
      ],
      settingSnapshots: const [
        DoorSettingSnapshot(
          code: DeviceCapabilityCode.autoClose,
          label: 'Auto close',
          supported: true,
          configured: true,
          currentValue: 30,
          unit: 's',
        ),
      ],
    );

    expect(find.text('30 s'), findsOneWidget);
    await tester.tap(find.text('Auto close'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DeviceCapabilityOptionsSheet>(
            find.byType(DeviceCapabilityOptionsSheet),
          )
          .initialValue,
      30,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('shows unavailable when the server auto-close value is null', (
    tester,
  ) async {
    final gateway = MockHardwareGateway(
      autoCloseAttributeId: 0x2725,
      autoCloseValue: 75,
    );
    await _pumpSettingsRouter(
      tester,
      gateway: gateway,
      settingSnapshots: const [
        DoorSettingSnapshot(
          code: DeviceCapabilityCode.autoClose,
          label: 'Auto close',
          supported: true,
          configured: false,
          unit: 's',
        ),
      ],
    );

    expect(find.text('Not reported'), findsWidgets);
    expect(find.text('0x004B (75)'), findsNothing);
  });

  testWidgets('localizes known setting titles instead of server labels', (
    tester,
  ) async {
    await _pumpSettingsRouter(
      tester,
      locale: const Locale('zh'),
      capabilityDefinitions: const [
        DeviceCapability(
          code: DeviceCapabilityCode.ledOffDelay,
          label: 'Server LED off delay',
        ),
        DeviceCapability(
          code: DeviceCapabilityCode.partialOpenLevel,
          label: 'Server partial open',
        ),
        DeviceCapability(
          code: DeviceCapabilityCode.autoClose,
          label: 'Server auto close',
        ),
        DeviceCapability(
          code: DeviceCapabilityCode.doorOpenReminder,
          label: 'Server door open reminder',
        ),
      ],
      settingSnapshots: const [
        DoorSettingSnapshot(
          code: DeviceCapabilityCode.ledOffDelay,
          label: 'Server LED off delay setting',
          supported: true,
          configured: true,
        ),
        DoorSettingSnapshot(
          code: DeviceCapabilityCode.partialOpen,
          label: 'Server partial open setting',
          supported: true,
          configured: true,
        ),
        DoorSettingSnapshot(
          code: DeviceCapabilityCode.autoClose,
          label: 'Server auto close setting',
          supported: true,
          configured: true,
        ),
        DoorSettingSnapshot(
          code: DeviceCapabilityCode.doorOpenReminder,
          label: 'Server door open reminder setting',
          supported: true,
          configured: true,
        ),
      ],
    );

    expect(find.text('LED 熄灭延时'), findsOneWidget);
    expect(find.text('部分开启'), findsOneWidget);
    expect(find.text('自动关闭'), findsOneWidget);
    expect(find.text('开门提醒'), findsOneWidget);
    expect(find.textContaining('Server '), findsNothing);
  });

  testWidgets('accepts a hexadecimal raw value and refreshes the page', (
    tester,
  ) async {
    final reports = <_ReportedOperation>[];
    await _pumpSettingsRouter(
      tester,
      operationRecordRepository: _RecordingOperationRecordRepository(reports),
    );

    await tester.tap(find.text('LED off delay'));
    await tester.pumpAndSettle();
    expect(find.text('Raw value'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0x09');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('0x09 (9)'), findsOneWidget);
    expect(reports.single.action, OperationReportAction.ledOffDelayChanged);
    expect(reports.single.operationSource, OperationReportSource.bluetooth);
  });

  testWidgets('reports all four supported settings after successful writes', (
    tester,
  ) async {
    final reports = <_ReportedOperation>[];
    await _pumpSettingsRouter(
      tester,
      operationRecordRepository: _RecordingOperationRecordRepository(reports),
    );

    await _saveRawSetting(tester, 'LED off delay', '9');
    await _saveRawSetting(tester, 'Partial open', '8');
    await _saveOptionSetting(tester, 'Auto close');
    await _saveRawSetting(tester, 'Door open reminder', '5');

    expect(reports.map((report) => report.action), [
      OperationReportAction.ledOffDelayChanged,
      OperationReportAction.partialOpenChanged,
      OperationReportAction.autoCloseDelayChanged,
      OperationReportAction.doorOpenReminderDelayChanged,
    ]);
    expect(
      reports.map((report) => report.operationSource),
      everyElement(OperationReportSource.bluetooth),
    );
  });

  testWidgets('does not report installer-only or failed settings writes', (
    tester,
  ) async {
    final reports = <_ReportedOperation>[];
    await _pumpSettingsRouter(
      tester,
      gateway: _FailingSettingsHardwareGateway(),
      operationRecordRepository: _RecordingOperationRecordRepository(reports),
    );

    await _saveRawSetting(tester, 'Opening speed', '70');
    await _saveRawSetting(tester, 'Force margin', '2');
    await _saveRawSetting(tester, 'LED off delay', '9');
    expect(reports, isEmpty);
  });

  testWidgets('validates raw values against their byte width', (tester) async {
    await _pumpSettingsRouter(tester);

    await tester.tap(find.text('Force margin'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '256');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Enter a value from 0 to 255.'), findsOneWidget);
  });

  testWidgets('rejects raw values outside the device protocol range', (
    tester,
  ) async {
    await _pumpSettingsRouter(tester);

    await tester.tap(find.text('LED off delay'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '10');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Enter a value supported by the device.'), findsOneWidget);
  });

  testWidgets('requires the selected Bluetooth name to be connected', (
    tester,
  ) async {
    await _pumpSettingsRouter(tester, bleConnected: false);

    await tester.tap(find.text('LED off delay'));
    await tester.pump();

    expect(find.text('Raw value'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('requires the connected Bluetooth name to match the device', (
    tester,
  ) async {
    await _pumpSettingsRouter(tester, matchingBleName: false);

    await tester.tap(find.text('LED off delay'));
    await tester.pump();

    expect(find.text('Raw value'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('uses option labels and units while saving option values', (
    tester,
  ) async {
    await _pumpSettingsRouter(
      tester,
      capabilityDefinitions: const [
        DeviceCapability(
          code: DeviceCapabilityCode.ledOffDelay,
          label: 'LED off delay',
          unit: 's',
          options: [
            DeviceCapabilityOption(value: 5, label: '5'),
            DeviceCapabilityOption(value: 9, label: '9'),
          ],
        ),
      ],
      settingSnapshots: const [
        DoorSettingSnapshot(
          code: DeviceCapabilityCode.ledOffDelay,
          label: 'LED off delay',
          supported: true,
          configured: true,
          currentValue: 5,
          unit: 's',
        ),
      ],
    );

    expect(find.text('5 s'), findsOneWidget);
    await tester.tap(find.text('LED off delay'));
    await tester.pumpAndSettle();
    expect(find.text('9 s'), findsOneWidget);

    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -50));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('9 s'), findsOneWidget);
  });

  testWidgets('preserves server-driven auto-close option counts and order', (
    tester,
  ) async {
    for (final optionCount in <int>[7, 9]) {
      final options = List<DeviceCapabilityOption>.generate(
        optionCount,
        (index) => DeviceCapabilityOption(
          value: (index + 1) * 15,
          label: 'Level ${index + 1}',
        ),
      );
      await _pumpSettingsRouter(
        tester,
        capabilityDefinitions: [
          DeviceCapability(
            code: DeviceCapabilityCode.autoClose,
            label: 'Auto close',
            unit: 's',
            options: options,
          ),
        ],
      );

      await tester.tap(find.text('Auto close'));
      await tester.pumpAndSettle();
      final sheet = tester.widget<DeviceCapabilityOptionsSheet>(
        find.byType(DeviceCapabilityOptionsSheet),
      );
      expect(sheet.options.map((option) => option.value), [
        for (var index = 1; index <= optionCount; index++) index * 15,
      ]);
      expect(sheet.options.map((option) => option.label), [
        for (var index = 1; index <= optionCount; index++) 'Level $index',
      ]);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('does not open a raw editor when auto-close options are empty', (
    tester,
  ) async {
    await _pumpSettingsRouter(
      tester,
      capabilityDefinitions: const [
        DeviceCapability(
          code: DeviceCapabilityCode.autoClose,
          label: 'Auto close',
        ),
      ],
    );

    await tester.tap(find.text('Auto close'));
    await tester.pumpAndSettle();

    expect(find.byType(DeviceCapabilityOptionsSheet), findsNothing);
    expect(find.text('Raw value'), findsNothing);
  });

  testWidgets('does not refetch door settings after a BLE auto-close write', (
    tester,
  ) async {
    final doorSettingsRepository = _CountingDoorSettingsRepository();
    await _pumpSettingsRouter(
      tester,
      doorSettingsRepository: doorSettingsRepository,
      capabilityDefinitions: const [
        DeviceCapability(
          code: DeviceCapabilityCode.autoClose,
          label: 'Auto close',
          unit: 's',
          options: [
            DeviceCapabilityOption(value: 15, label: '15'),
            DeviceCapabilityOption(value: 30, label: '30'),
          ],
        ),
      ],
    );
    expect(doorSettingsRepository.fetchCount, 1);

    await _saveOptionSetting(tester, 'Auto close');

    expect(doorSettingsRepository.fetchCount, 1);
  });

  testWidgets('preselects the configured option when opening its editor', (
    tester,
  ) async {
    await _pumpSettingsRouter(
      tester,
      capabilities: const [DeviceCapabilityCode.autoClose],
      capabilityDefinitions: const [
        DeviceCapability(
          code: DeviceCapabilityCode.autoClose,
          label: 'Auto close',
          unit: 'min',
          options: [
            DeviceCapabilityOption(value: 1, label: '1'),
            DeviceCapabilityOption(value: 3, label: '3'),
            DeviceCapabilityOption(value: 5, label: '5'),
          ],
        ),
      ],
      settingSnapshots: const [
        DoorSettingSnapshot(
          code: DeviceCapabilityCode.autoClose,
          label: 'Auto close',
          supported: true,
          configured: true,
          currentValue: 3,
          unit: 'min',
        ),
      ],
    );

    await tester.tap(find.text('Auto close'));
    await tester.pumpAndSettle();

    final selectionList = tester
        .widget<DeviceSettingsFixedSelectionList<DeviceCapabilityOption>>(
          find.byType(DeviceSettingsFixedSelectionList<DeviceCapabilityOption>),
        );
    final controller =
        tester
                .widget<ListWheelScrollView>(
                  find.descendant(
                    of: find.byWidget(selectionList),
                    matching: find.byType(ListWheelScrollView),
                  ),
                )
                .controller!
            as FixedExtentScrollController;
    expect(controller.selectedItem, 1);
  });

  testWidgets('renders current settings returned for the door', (tester) async {
    await _pumpSettingsRouter(
      tester,
      capabilityDefinitions: const [
        DeviceCapability(
          code: DeviceCapabilityCode.ledOffDelay,
          label: 'LED off delay',
          options: [DeviceCapabilityOption(value: 30, label: '30')],
        ),
      ],
      settingSnapshots: const [
        DoorSettingSnapshot(
          code: DeviceCapabilityCode.ledOffDelay,
          label: '',
          supported: true,
          configured: true,
          currentValue: 30,
          unit: 's',
        ),
      ],
    );

    expect(find.text('30 s'), findsOneWidget);
  });

  testWidgets('navigates to transmitter page', (tester) async {
    await _pumpSettingsRouter(tester);

    await tester.tap(find.text('Transmitter management'));
    await tester.pumpAndSettle();
    expect(find.text('Transmitter learning'), findsOneWidget);
  });

  testWidgets('aligns all settings row chevrons to the same trailing inset', (
    tester,
  ) async {
    await _pumpSettingsRouter(tester);

    final chevrons = find.byIcon(Icons.chevron_right).evaluate().map((element) {
      final renderBox = element.renderObject! as RenderBox;
      final topLeft = renderBox.localToGlobal(Offset.zero);
      return Rect.fromLTWH(
        topLeft.dx,
        topLeft.dy,
        renderBox.size.width,
        renderBox.size.height,
      );
    }).toList();
    expect(chevrons, isNotEmpty);
    expect(chevrons.map((rect) => rect.right).toSet(), hasLength(1));
    expect(chevrons.first.right, 373);
  });

  testWidgets('always shows the device information page', (tester) async {
    await _pumpSettingsRouter(tester, capabilities: const []);

    expect(find.text('About the device'), findsOneWidget);
  });

  testWidgets('shows the complete Bluetooth name on the about-device page', (
    tester,
  ) async {
    const bluetoothName = 'opener_B8F86211A9DC';
    await _pumpSettingsRouter(
      tester,
      doorDetailRepository: const _AboutDeviceInfoRepository(
        AboutDeviceInfo(
          deviceId: 'mock-device',
          sn: 'B8F86211A9DC',
          deviceType: 'opener',
          deviceTypeLabel: 'Opener',
          bluetoothName: bluetoothName,
          hardwareVersion: '1.0.0',
          firmwareVersion: '1.0.0',
          updateAvailable: false,
          availableVersion: '',
        ),
      ),
    );

    await tester.tap(find.text('About the device'));
    await tester.pumpAndSettle();

    final bluetoothNameText = tester.widget<Text>(find.text(bluetoothName));
    expect(bluetoothNameText.maxLines, isNull);
    expect(bluetoothNameText.overflow, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders on a compact screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpSettingsRouter(tester, setDefaultSize: false);

    expect(tester.takeException(), isNull);
  });

  testWidgets('filters settings using the fetched capability codes', (
    tester,
  ) async {
    await _pumpSettingsRouter(
      tester,
      capabilities: const [DeviceCapabilityCode.ledOffDelay, 'UNKNOWN_SETTING'],
    );

    expect(find.text('Transmitter management'), findsNothing);
    expect(find.text('LED off delay'), findsOneWidget);
    expect(find.text('Partial open'), findsNothing);
    expect(find.text('Auto close'), findsNothing);
    expect(find.text('Opening speed'), findsNothing);
    expect(find.text('Door open reminder'), findsNothing);
    expect(find.text('Force margin'), findsNothing);
    expect(find.text('UNKNOWN_SETTING'), findsNothing);
    expect(find.text('About the device'), findsOneWidget);
  });

  testWidgets('filters capability settings using the navigation scope', (
    tester,
  ) async {
    await _pumpSettingsRouter(
      tester,
      capabilityScope: DeviceSettingsCapabilityScope(
        allowedCapabilityCodes: const [DeviceCapabilityCode.ledOffDelay],
      ),
    );

    expect(find.text('LED off delay'), findsOneWidget);
    expect(find.text('Transmitter management'), findsNothing);
    expect(find.text('Partial open'), findsNothing);
    expect(find.text('Auto close'), findsNothing);
    expect(find.text('Opening speed'), findsNothing);
    expect(find.text('Door open reminder'), findsNothing);
    expect(find.text('Force margin'), findsNothing);
    expect(find.text('About the device'), findsOneWidget);
  });
}

Future<void> _pumpSettingsRouter(
  WidgetTester tester, {
  bool setDefaultSize = true,
  Locale? locale,
  bool bleConnected = true,
  bool matchingBleName = true,
  List<String> capabilities = const [
    DeviceCapabilityCode.transmitterPairing,
    DeviceCapabilityCode.ledOffDelay,
    DeviceCapabilityCode.partialOpenLevel,
    DeviceCapabilityCode.autoClose,
    DeviceCapabilityCode.openingSpeed,
    DeviceCapabilityCode.doorOpenReminder,
    DeviceCapabilityCode.forceMargin,
  ],
  List<DeviceCapability>? capabilityDefinitions,
  List<DoorSettingSnapshot> settingSnapshots = const [],
  DoorSettingsRepository? doorSettingsRepository,
  OperationRecordRepository? operationRecordRepository,
  MockHardwareGateway? gateway,
  DeviceSettingsCapabilityScope? capabilityScope,
  DoorDetailRepository? doorDetailRepository,
}) async {
  if (setDefaultSize) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  final hardwareGateway = gateway ?? MockHardwareGateway();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deviceCommandControllerProvider.overrideWith(
          !bleConnected
              ? _DisconnectedDeviceCommandController.new
              : matchingBleName
              ? _ConnectedDeviceCommandController.new
              : _OtherDeviceCommandController.new,
        ),
        deviceSettingsHardwareGatewayProvider.overrideWithValue(
          hardwareGateway,
        ),
        deviceCapabilityRepositoryProvider.overrideWithValue(
          _FakeDeviceCapabilityRepository(
            capabilityDefinitions ??
                [
                  for (final code in capabilities)
                    DeviceCapability(
                      code: code,
                      label: _FakeDeviceCapabilityRepository.labelFor(code),
                      unit: code == DeviceCapabilityCode.autoClose ? 's' : null,
                      options: code == DeviceCapabilityCode.autoClose
                          ? const [
                              DeviceCapabilityOption(value: 15, label: '15'),
                              DeviceCapabilityOption(value: 30, label: '30'),
                            ]
                          : const [],
                    ),
                ],
          ),
        ),
        doorSettingsRepositoryProvider.overrideWithValue(
          doorSettingsRepository ??
              _FakeDoorSettingsRepository(settingSnapshots),
        ),
        operationRecordRepositoryProvider.overrideWithValue(
          operationRecordRepository ??
              const _RecordingOperationRecordRepository(),
        ),
        if (doorDetailRepository != null)
          doorDetailRepositoryProvider.overrideWithValue(doorDetailRepository),
      ],
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          initialLocation:
              '${DeviceSettingsPage.routePath}'
              '?doorId=12&deviceId=mock-device&bleName=mock-device',
          initialExtra: capabilityScope,
          routes: [
            GoRoute(
              path: DeviceSettingsPage.routePath,
              builder: (context, state) => DeviceSettingsPage(
                doorId: state.uri.queryParameters['doorId'] ?? '',
                deviceId: state.uri.queryParameters['deviceId'] ?? '',
                bleName: state.uri.queryParameters['bleName'] ?? '',
                bleDeviceId:
                    state.uri.queryParameters['bleDeviceId'] ?? 'mock-device',
                capabilityScope: state.extra is DeviceSettingsCapabilityScope
                    ? state.extra as DeviceSettingsCapabilityScope
                    : null,
              ),
            ),
            GoRoute(
              path: AboutDevicePage.routePath,
              builder: (context, state) => AboutDevicePage(
                doorId: state.uri.queryParameters['doorId'] ?? '',
                deviceId: state.uri.queryParameters['deviceId'] ?? '',
              ),
            ),
            GoRoute(
              path: TransmitterManagementPage.routePath,
              builder: (context, state) => TransmitterManagementPage(
                deviceId: state.uri.queryParameters['deviceId'] ?? '',
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _saveRawSetting(
  WidgetTester tester,
  String title,
  String value,
) async {
  await tester.tap(find.text(title).first);
  await tester.pumpAndSettle();
  expect(find.text('Raw value'), findsOneWidget);
  await tester.enterText(find.byType(TextField), value);
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

Future<void> _saveOptionSetting(WidgetTester tester, String title) async {
  await tester.tap(find.text(title).first);
  await tester.pumpAndSettle();
  expect(find.byType(DeviceCapabilityOptionsSheet), findsOneWidget);
  await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -50));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Confirm'));
  await tester.pumpAndSettle();
}

class _ConnectedDeviceCommandController extends DeviceCommandController {
  @override
  DeviceCommandState build() {
    return const DeviceCommandState(
      bleConnectionStatus: DeviceBleConnectionStatus.connected,
      bleTargetName: 'mock-device',
    );
  }
}

class _DisconnectedDeviceCommandController extends DeviceCommandController {
  @override
  DeviceCommandState build() => const DeviceCommandState();
}

class _OtherDeviceCommandController extends DeviceCommandController {
  @override
  DeviceCommandState build() {
    return const DeviceCommandState(
      bleConnectionStatus: DeviceBleConnectionStatus.connected,
      bleTargetName: 'other-device',
    );
  }
}

class _AboutDeviceInfoRepository implements DoorDetailRepository {
  const _AboutDeviceInfoRepository(this.info);

  final AboutDeviceInfo info;

  @override
  Future<AboutDeviceInfo> fetchAboutDeviceInfo({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) async => info;

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) => throw UnimplementedError();
}

class _FakeDoorSettingsRepository implements DoorSettingsRepository {
  const _FakeDoorSettingsRepository(this.settings);

  final List<DoorSettingSnapshot> settings;

  @override
  Future<List<DoorSettingSnapshot>> fetchSettings({
    required String doorId,
    required String requestId,
  }) async => settings;
}

class _CountingDoorSettingsRepository implements DoorSettingsRepository {
  int fetchCount = 0;

  @override
  Future<List<DoorSettingSnapshot>> fetchSettings({
    required String doorId,
    required String requestId,
  }) async {
    fetchCount += 1;
    return const [
      DoorSettingSnapshot(
        code: DeviceCapabilityCode.autoClose,
        label: 'Auto close',
        supported: true,
        configured: true,
        currentValue: 15,
        unit: 's',
      ),
    ];
  }
}

class _FakeDeviceCapabilityRepository implements DeviceCapabilityRepository {
  const _FakeDeviceCapabilityRepository(this.capabilities);

  final List<DeviceCapability> capabilities;

  static const _labels = {
    DeviceCapabilityCode.transmitterPairing: 'Transmitter pairing',
    DeviceCapabilityCode.ledOffDelay: 'LED off delay',
    DeviceCapabilityCode.partialOpenLevel: 'Partial open',
    DeviceCapabilityCode.autoClose: 'Auto close',
    DeviceCapabilityCode.openingSpeed: 'Opening speed',
    DeviceCapabilityCode.doorOpenReminder: 'Door open reminder',
    DeviceCapabilityCode.forceMargin: 'Force margin',
  };

  static String labelFor(String code) => _labels[code] ?? code;

  @override
  Future<List<DeviceCapability>> fetchCapabilities({
    required String deviceId,
    required String requestId,
  }) async => capabilities;
}

class _ReportedOperation {
  const _ReportedOperation({
    required this.doorId,
    required this.action,
    required this.operationSource,
    required this.requestId,
  });

  final String doorId;
  final OperationReportAction action;
  final OperationReportSource operationSource;
  final String requestId;
}

class _RecordingOperationRecordRepository implements OperationRecordRepository {
  const _RecordingOperationRecordRepository([this.reports]);

  final List<_ReportedOperation>? reports;

  @override
  Future<void> reportOperation({
    required String doorId,
    required OperationReportAction action,
    required OperationReportSource operationSource,
    required String requestId,
  }) async {
    reports?.add(
      _ReportedOperation(
        doorId: doorId,
        action: action,
        operationSource: operationSource,
        requestId: requestId,
      ),
    );
  }

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

class _FailingSettingsHardwareGateway extends MockHardwareGateway {
  @override
  Future<DeviceAttributeWriteResult> setDeviceAttributes({
    required String requestId,
    required String deviceId,
    required List<DeviceAttribute> attributes,
  }) async {
    return DeviceAttributeWriteResult(
      requestId: requestId,
      deviceId: deviceId,
      success: false,
      sequence: 1,
    );
  }
}
