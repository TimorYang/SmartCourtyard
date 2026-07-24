import 'dart:ui' show Tristate;

import 'package:flinx/features/device_control/presentation/pages/device_settings_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flinx/shared/widgets/flinx_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders settings rows and default values', (tester) async {
    await _pumpSettingsRouter(tester);

    expect(find.text('Setting'), findsOneWidget);
    expect(find.text('For users'), findsOneWidget);
    expect(find.text('Transmitter management'), findsOneWidget);
    expect(find.text('LED off delay'), findsOneWidget);
    expect(find.text('3 min'), findsOneWidget);
    expect(find.text('Partial open'), findsOneWidget);
    expect(find.text('12 min'), findsOneWidget);
    expect(find.text('Auto close'), findsOneWidget);
    expect(find.text('15s'), findsOneWidget);
    expect(find.text('Opening speed'), findsOneWidget);
    expect(find.text('GMT+8:00'), findsOneWidget);
    expect(find.text('About the device'), findsOneWidget);
    expect(find.text('Door open reminder'), findsOneWidget);
    expect(find.text('For installers'), findsOneWidget);
    expect(find.text('Force margin'), findsOneWidget);
    expect(find.byType(FlinxSwitch), findsOneWidget);
  });

  testWidgets('toggles door open reminder with the shared switch', (
    tester,
  ) async {
    await _pumpSettingsRouter(tester);

    final toggle = find.byType(FlinxSwitch);
    expect(
      tester.getSemantics(toggle).flagsCollection.isToggled,
      Tristate.isTrue,
    );

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(toggle).flagsCollection.isToggled,
      Tristate.isFalse,
    );
  });

  testWidgets('opens the door open reminder time sheet from its setting row', (
    tester,
  ) async {
    await _pumpSettingsRouter(tester);

    await tester.tap(find.text('Door open reminder'));
    await tester.pumpAndSettle();

    expect(find.text('Door open reminder time'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
    expect(find.byType(ListWheelScrollView), findsOneWidget);
  });

  testWidgets('opening speed snaps to externally supplied discrete values', (tester) async {
    await _pumpSettingsRouter(
      tester,
      openingSpeedConfig: OpeningSpeedConfig(allowedValues: [100, 80, 60], current: 80),
    );

    await tester.tap(find.text('Opening speed'));
    await tester.pumpAndSettle();

    expect(find.text('Current setting: 80% (motor setting)'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('60%\n(STD)'), findsOneWidget);
    expect(find.textContaining('(STD)'), findsOneWidget);
    expect(find.byKey(const Key('openingSpeedSliderGuide-0')), findsOneWidget);
    expect(find.byKey(const Key('openingSpeedSliderGuide-1')), findsOneWidget);
    expect(find.byKey(const Key('openingSpeedSliderGuide-2')), findsOneWidget);
    expect(tester.getRect(find.text('100%')).right, equals(tester.view.physicalSize.width / tester.view.devicePixelRatio - 35));

    final slider = find.byKey(const Key('openingSpeedDiscreteSlider'));
    final thumb = find.descendant(of: slider, matching: find.byIcon(Icons.drag_handle));
    await tester.tapAt(tester.getTopLeft(slider) + const Offset(20, 4));
    await tester.pump();
    expect(find.text('Current setting: 100% (motor setting)'), findsOneWidget);
    expect(tester.getTopLeft(thumb).dy, greaterThanOrEqualTo(tester.getTopLeft(slider).dy));

    await tester.tapAt(tester.getBottomLeft(slider) + const Offset(20, -4));
    await tester.pump();
    expect(find.text('Current setting: 60% (motor setting)'), findsOneWidget);
    expect(find.textContaining('Current setting: 90%'), findsNothing);
    expect(tester.getBottomLeft(thumb).dy, lessThanOrEqualTo(tester.getBottomLeft(slider).dy));
  });

  testWidgets('force margin retains its continuous slider', (tester) async {
    await _pumpSettingsRouter(tester);

    await tester.tap(find.text('Force margin'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('forceMarginSliderGuide-0')), findsOneWidget);
    expect(find.byKey(const Key('forceMarginSliderGuide-1')), findsOneWidget);
    expect(tester.getRect(find.text('+15%')).right, equals(tester.view.physicalSize.width / tester.view.devicePixelRatio - 35));

    final slider = find.byKey(const Key('forceMarginContinuousSlider'));
    final thumb = find.descendant(of: slider, matching: find.byIcon(Icons.drag_handle));
    final initialThumbTop = tester.getTopLeft(thumb).dy;

    await tester.tapAt(tester.getTopLeft(slider) + const Offset(20, 4));
    await tester.pump();

    expect(tester.getTopLeft(thumb).dy, lessThan(initialThumbTop));
    expect(tester.getTopLeft(thumb).dy, greaterThanOrEqualTo(tester.getTopLeft(slider).dy));
    expect(find.byKey(const Key('openingSpeedDiscreteSlider')), findsNothing);
  });

  testWidgets('updates LED off delay from bottom sheet', (tester) async {
    await _pumpSettingsRouter(tester);

    await tester.tap(find.text('LED off delay'));
    await tester.pumpAndSettle();

    expect(find.text('1 min'), findsOneWidget);
    expect(find.byType(ListWheelScrollView), findsOneWidget);
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -92));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('5 min'), findsOneWidget);
  });

  testWidgets('updates partial open height from bottom sheet', (tester) async {
    await _pumpSettingsRouter(tester);

    await tester.tap(find.text('Partial open'));
    await tester.pumpAndSettle();

    expect(find.text('Partial open height'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.byType(ListWheelScrollView), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('updates auto close setting from bottom sheet', (tester) async {
    await _pumpSettingsRouter(tester);

    await tester.tap(find.text('Auto close'));
    await tester.pumpAndSettle();

    expect(find.text('Auto closing setting'), findsOneWidget);
    expect(find.text('Any position'), findsOneWidget);
    expect(find.byType(ListWheelScrollView), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('1 min'), findsOneWidget);
  });

  testWidgets('cancel dismisses setting sheet without updating value', (
    tester,
  ) async {
    await _pumpSettingsRouter(tester);

    await tester.tap(find.text('LED off delay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('LED off delay'), findsOneWidget);
    expect(find.text('3 min'), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('navigates to about device and transmitter pages', (
    tester,
  ) async {
    await _pumpSettingsRouter(tester);

    await tester.tap(find.text('About the device'));
    await tester.pumpAndSettle();

    expect(find.text('Bluetooth name'), findsOneWidget);
    expect(find.text('Firmware version'), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transmitter management'));
    await tester.pumpAndSettle();

    expect(find.text('Setting'), findsOneWidget);
    expect(find.text('Transmitter learning'), findsOneWidget);
    expect(find.text('Management'), findsOneWidget);
  });

  testWidgets('renders on a compact screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpSettingsRouter(tester);

    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSettingsRouter(
  WidgetTester tester, {
  OpeningSpeedConfig? openingSpeedConfig,
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        initialLocation: '${DeviceSettingsPage.routePath}?deviceId=mock-device',
        routes: [
          GoRoute(
            path: DeviceSettingsPage.routePath,
            builder: (context, state) => DeviceSettingsPage(
              deviceId: state.uri.queryParameters['deviceId'] ?? '',
              openingSpeedConfig: openingSpeedConfig ?? OpeningSpeedConfig(allowedValues: [100, 80, 60], current: 80),
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
  );
  await tester.pumpAndSettle();
}
