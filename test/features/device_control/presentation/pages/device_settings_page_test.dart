import 'package:flinx/features/device_control/presentation/pages/device_settings_page.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
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
    await _saveRawSetting(tester, 'Auto close', '1');
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
      capabilities: const [DeviceCapabilityCode.ledOffDelay],
    );

    expect(find.text('Transmitter management'), findsNothing);
    expect(find.text('LED off delay'), findsOneWidget);
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
  OperationRecordRepository? operationRecordRepository,
  MockHardwareGateway? gateway,
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
                    ),
                ],
          ),
        ),
        doorSettingsRepositoryProvider.overrideWithValue(
          _FakeDoorSettingsRepository(settingSnapshots),
        ),
        operationRecordRepositoryProvider.overrideWithValue(
          operationRecordRepository ??
              const _RecordingOperationRecordRepository(),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          initialLocation:
              '${DeviceSettingsPage.routePath}'
              '?doorId=12&deviceId=mock-device&bleName=mock-device',
          routes: [
            GoRoute(
              path: DeviceSettingsPage.routePath,
              builder: (context, state) => DeviceSettingsPage(
                doorId: state.uri.queryParameters['doorId'] ?? '',
                deviceId: state.uri.queryParameters['deviceId'] ?? '',
                bleName: state.uri.queryParameters['bleName'] ?? '',
                bleDeviceId:
                    state.uri.queryParameters['bleDeviceId'] ?? 'mock-device',
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

class _FakeDoorSettingsRepository implements DoorSettingsRepository {
  const _FakeDoorSettingsRepository(this.settings);

  final List<DoorSettingSnapshot> settings;

  @override
  Future<List<DoorSettingSnapshot>> fetchSettings({
    required String doorId,
    required String requestId,
  }) async => settings;
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
