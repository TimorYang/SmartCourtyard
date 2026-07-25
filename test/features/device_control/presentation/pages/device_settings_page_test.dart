import 'package:flinx/features/device_control/presentation/pages/device_settings_page.dart';
import 'package:flinx/features/settings/application/providers.dart';
import 'package:flinx/features/settings/domain/entities/device_capability.dart';
import 'package:flinx/features/settings/domain/entities/door_setting_snapshot.dart';
import 'package:flinx/features/settings/domain/repositories/device_capability_repository.dart';
import 'package:flinx/features/settings/domain/repositories/door_settings_repository.dart';
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
    expect(find.text('0x1E (30)'), findsOneWidget);
    expect(find.text('Partial open'), findsOneWidget);
    expect(find.text('0x07 (7)'), findsOneWidget);
    expect(find.text('Auto close'), findsOneWidget);
    expect(find.text('0x0000 (0)'), findsOneWidget);
    expect(find.text('Force margin'), findsOneWidget);
  });

  testWidgets('accepts a hexadecimal raw value and refreshes the page', (
    tester,
  ) async {
    await _pumpSettingsRouter(tester);

    await tester.tap(find.text('LED off delay'));
    await tester.pumpAndSettle();
    expect(find.text('Raw value'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0x20');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('0x20 (32)'), findsOneWidget);
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
            DeviceCapabilityOption(value: 30, label: '30'),
            DeviceCapabilityOption(value: 60, label: '60'),
          ],
        ),
      ],
    );

    expect(find.text('30 s'), findsOneWidget);
    await tester.tap(find.text('LED off delay'));
    await tester.pumpAndSettle();
    expect(find.text('60 s'), findsOneWidget);

    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -50));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('60 s'), findsOneWidget);
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
}) async {
  if (setDefaultSize) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  final gateway = MockHardwareGateway();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deviceSettingsHardwareGatewayProvider.overrideWithValue(gateway),
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
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          initialLocation:
              '${DeviceSettingsPage.routePath}?doorId=12&deviceId=mock-device',
          routes: [
            GoRoute(
              path: DeviceSettingsPage.routePath,
              builder: (context, state) => DeviceSettingsPage(
                doorId: state.uri.queryParameters['doorId'] ?? '',
                deviceId: state.uri.queryParameters['deviceId'] ?? '',
              ),
            ),
            GoRoute(
              path: AboutDevicePage.routePath,
              builder: (context, state) => AboutDevicePage(
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
