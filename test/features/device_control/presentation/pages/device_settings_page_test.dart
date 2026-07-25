import 'package:flinx/features/device_control/presentation/pages/device_settings_page.dart';
import 'package:flinx/features/settings/application/providers.dart';
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
    expect(find.text('Auto close condition'), findsOneWidget);
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

  testWidgets('navigates to about device page', (tester) async {
    await _pumpSettingsRouter(tester);

    await tester.tap(find.text('About the device'));
    await tester.pumpAndSettle();
    expect(find.text('Bluetooth name'), findsOneWidget);
  });

  testWidgets('navigates to transmitter page', (tester) async {
    await _pumpSettingsRouter(tester);

    await tester.tap(find.text('Transmitter management'));
    await tester.pumpAndSettle();
    expect(find.text('Transmitter learning'), findsOneWidget);
  });

  testWidgets('renders on a compact screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpSettingsRouter(tester, setDefaultSize: false);

    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSettingsRouter(
  WidgetTester tester, {
  bool setDefaultSize = true,
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
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          initialLocation:
              '${DeviceSettingsPage.routePath}?deviceId=mock-device',
          routes: [
            GoRoute(
              path: DeviceSettingsPage.routePath,
              builder: (context, state) => DeviceSettingsPage(
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
