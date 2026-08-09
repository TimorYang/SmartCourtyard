import 'dart:async';

import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/features/add_device/domain/entities/onboarded_force_door.dart';
import 'package:flinx/features/add_device/domain/entities/onboarding_device_key.dart';
import 'package:flinx/features/add_device/domain/repositories/add_device_onboarding_repository.dart';
import 'package:flinx/features/add_device/presentation/pages/add_device_page.dart';
import 'package:flinx/features/add_device/presentation/pages/add_new_doors_page.dart';
import 'package:flinx/features/add_device/presentation/pages/f_box_connection_guide_page.dart';
import 'package:flinx/features/add_device/presentation/pages/smart_opener_ble_scan_page.dart';
import 'package:flinx/features/add_device/presentation/pages/smart_opener_choose_wifi_page.dart';
import 'package:flinx/features/add_device/presentation/pages/smart_opener_connecting_page.dart';
import 'package:flinx/features/add_device/presentation/pages/smart_opener_connection_success_page.dart';
import 'package:flinx/features/add_device/presentation/pages/smart_opener_device_not_found_page.dart';
import 'package:flinx/features/add_device/presentation/pages/smart_opener_qr_scan_page.dart';
import 'package:flinx/features/add_device/presentation/pages/smart_opener_scan_guide_page.dart';
import 'package:flinx/features/add_device/presentation/pages/smart_opener_scan_results_page.dart';
import 'package:flinx/features/add_device/presentation/pages/usb_dongle_guide_page.dart';
import 'package:flinx/features/device_control/presentation/pages/already_added_devices_page.dart';
import 'package:flinx/features/device_control/presentation/pages/device_command_page.dart';
import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/features/home/domain/entities/home_scene.dart';
import 'package:flinx/features/home/presentation/pages/home_page.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flinx/shared/widgets/flinx_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  const scanDuration = Duration(milliseconds: 20);

  testWidgets('opens Smart Opener scan guide from add device page', (
    tester,
  ) async {
    await _pumpScanFlowTestApp(tester, AddDevicePage.routePath);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Smart Opener (Built-in Wi-Fi)'));
    await tester.pumpAndSettle();

    expect(
      find.text('Scan the QR code inside the package with your smart phone.'),
      findsOneWidget,
    );
  });

  testWidgets('opens QR scanner page from scan guide action', (tester) async {
    await _pumpScanFlowTestApp(tester, SmartOpenerScanGuidePage.routePath);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Scan'));
    await tester.pumpAndSettle();

    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Flashlight'), findsOneWidget);
  });

  testWidgets('opens Smart Opener scan guide from F-Box guide', (tester) async {
    await _pumpScanFlowTestApp(tester, FBoxConnectionGuidePage.routePath);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Scan the QR code inside the package with your smart phone.'),
      findsOneWidget,
    );
  });

  testWidgets('opens Smart Opener scan guide from USB dongle guide', (
    tester,
  ) async {
    await _pumpScanFlowTestApp(tester, UsbDongleGuidePage.routePath);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Scan the QR code inside the package with your smart phone.'),
      findsOneWidget,
    );
  });

  testWidgets('opens Bluetooth scanning page from QR scanner shortcut', (
    tester,
  ) async {
    await _pumpScanFlowTestApp(tester, SmartOpenerQrScanPage.routePath);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Scan Bluetooth devices'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Scanning'), findsOneWidget);
    expect(find.text('Scanning the device, please wait...'), findsOneWidget);
  });

  testWidgets('BLE scan opens scan results when devices are discovered', (
    tester,
  ) async {
    await _pumpScanFlowTestApp(
      tester,
      SmartOpenerBleScanPage.routePath,
      scanDuration: scanDuration,
    );
    await tester.pump();
    await tester.pump(scanDuration);
    await tester.pump();

    expect(find.text('SCAN RESULTS'), findsOneWidget);
    expect(find.text('Found 1 Devices'), findsOneWidget);
  });

  testWidgets('BLE scan shows discovered opener devices before timeout', (
    tester,
  ) async {
    await _pumpScanFlowTestApp(
      tester,
      SmartOpenerBleScanPage.routePath,
      scanDuration: const Duration(seconds: 30),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Scanning'), findsOneWidget);
    expect(find.text('opener_MOCK-SN-001'), findsOneWidget);
    expect(find.text('SCAN RESULTS'), findsNothing);
  });

  testWidgets('BLE scan Add connects and opens Choose Wi-Fi before timeout', (
    tester,
  ) async {
    await _pumpScanFlowTestApp(
      tester,
      SmartOpenerBleScanPage.routePath,
      scanDuration: const Duration(seconds: 30),
    );
    await tester.pump();
    await tester.pump();

    await _tapAddDevice(tester);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('CHOOSE WIFI'), findsOneWidget);
    expect(find.text('Select Wi-Fi'), findsWidgets);
  });

  testWidgets(
    'QR-targeted BLE scan automatically connects the matching device',
    (tester) async {
      await _pumpScanFlowTestApp(
        tester,
        '${SmartOpenerBleScanPage.routePath}?targetSn=opener_MOCK-SN-001',
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('CHOOSE WIFI'), findsOneWidget);
    },
  );

  testWidgets('BLE scan opens not found when no device is discovered', (
    tester,
  ) async {
    await _pumpScanFlowTestApp(
      tester,
      SmartOpenerBleScanPage.routePath,
      gateway: _NoDeviceHardwareGateway(),
      scanDuration: scanDuration,
    );
    await tester.pump();
    await tester.pump(scanDuration);
    await tester.pump();

    expect(find.text('Device not found'), findsOneWidget);
  });

  testWidgets('not found actions rescan and return home', (tester) async {
    await _pumpScanFlowTestApp(tester, SmartOpenerDeviceNotFoundPage.routePath);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Rescan'), 260);
    await tester.tap(find.text('Rescan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SmartOpenerBleScanPage), findsOneWidget);

    await _pumpScanFlowTestApp(tester, SmartOpenerDeviceNotFoundPage.routePath);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Back to home'), 260);
    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('Add connects and opens Choose Wi-Fi with Wi-Fi sheet', (
    tester,
  ) async {
    await _openScanResults(tester, scanDuration: scanDuration);

    await _tapAddDevice(tester);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('CHOOSE WIFI'), findsOneWidget);
    expect(find.text('Select Wi-Fi'), findsWidgets);
    expect(find.text('FLINX Office'), findsOneWidget);
  });

  testWidgets('selecting Wi-Fi fills SSID and Next reaches connecting flow', (
    tester,
  ) async {
    await _openChooseWifi(
      tester,
      gateway: _PendingWifiHardwareGateway(),
      scanDuration: scanDuration,
    );

    await tester.tap(find.text('FLINX Office'));
    await tester.pumpAndSettle();

    expect(find.text('FLINX Office'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'password123');
    await _scrollToAction(tester, 'NEXT');
    await _tapAction(tester, 'NEXT');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(SmartOpenerConnectingPage), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(0.95 * 0.35 / 8, 0.01),
    );

    await tester.pump(const Duration(seconds: 4));
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(0.95 * 4.35 / 8, 0.01),
    );

    await tester.pump(const Duration(seconds: 5));
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.95,
    );
  });

  testWidgets('Skip reaches connecting flow', (tester) async {
    await _openChooseWifi(
      tester,
      gateway: _PendingWifiHardwareGateway(),
      scanDuration: scanDuration,
    );

    await tester.tap(find.text('FLINX Office'));
    await tester.pumpAndSettle();
    await _scrollToAction(tester, 'Skip');
    await _tapAction(tester, 'Skip');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(SmartOpenerConnectingPage), findsOneWidget);
  });

  testWidgets('configure failure shows dialog and OK returns to Choose Wi-Fi', (
    tester,
  ) async {
    await _openChooseWifi(
      tester,
      gateway: _FailingWifiHardwareGateway(),
      scanDuration: scanDuration,
    );

    await tester.tap(find.text('FLINX Office'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bad-password');
    await _scrollToAction(tester, 'NEXT');
    await _tapAction(tester, 'NEXT');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.text(
        'Connection failed. Please check Wi-Fi password and try again.',
      ),
      findsOneWidget,
    );
    final stoppedProgress = tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value;
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      stoppedProgress,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('CHOOSE WIFI'), findsOneWidget);
  });

  testWidgets('connecting back sheet can cancel or return to scan results', (
    tester,
  ) async {
    await _openChooseWifi(
      tester,
      gateway: _PendingWifiHardwareGateway(),
      scanDuration: scanDuration,
    );

    await tester.tap(find.text('FLINX Office'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'password123');
    await _scrollToAction(tester, 'NEXT');
    await _tapAction(tester, 'NEXT');
    await tester.pumpAndSettle();

    expect(find.byType(SmartOpenerConnectingPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('STOP DEVICE ADDITION'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(SmartOpenerConnectingPage), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('SCAN RESULTS'), findsOneWidget);
  });

  for (final useSystemBack in [false, true]) {
    testWidgets('Try it removes onboarding routes and '
        '${useSystemBack ? 'system' : 'app bar'} back returns home', (
      tester,
    ) async {
      var homeDeviceRequests = 0;
      final container = ProviderContainer(
        overrides: [
          addDeviceHardwareGatewayProvider.overrideWithValue(
            MockHardwareGateway(),
          ),
          addDeviceOnboardingRepositoryProvider.overrideWithValue(
            const _FakeAddDeviceOnboardingRepository(),
          ),
          homeDevicesProvider.overrideWith((ref) async {
            homeDeviceRequests += 1;
            return const <DeviceSummary>[];
          }),
        ],
      );
      addTearDown(container.dispose);
      await container.read(homeDevicesProvider.future);
      expect(homeDeviceRequests, 1);

      await _pumpScanFlowTestApp(
        tester,
        HomePage.routePath,
        scanDuration: scanDuration,
        container: container,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('New door'));
      await tester.pumpAndSettle();
      expect(find.byType(AddNewDoorsPage), findsOneWidget);

      await tester.tap(find.text('Garage door'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Smart Opener (Built-in Wi-Fi)'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Scan'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Scan Bluetooth devices'));
      await tester.pump();
      await tester.pump(scanDuration);
      await tester.pump();
      expect(find.text('SCAN RESULTS'), findsOneWidget);

      await _tapAddDevice(tester);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('CHOOSE WIFI'), findsOneWidget);

      await tester.tap(find.text('FLINX Office'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'password123');
      await _scrollToAction(tester, 'NEXT');
      await _tapAction(tester, 'NEXT');
      await tester.pumpAndSettle();

      expect(find.text('Connection successful'), findsOneWidget);
      await container.read(homeDevicesProvider.future);
      expect(homeDeviceRequests, 2);
      final selectedDeviceId = container
          .read(addDeviceControllerProvider)
          .selectedDevice!
          .id;
      await tester.tap(find.widgetWithText(FilledButton, 'Try it'));
      await tester.pumpAndSettle();
      expect(
        find.text('Device command door=1 device=$selectedDeviceId'),
        findsOneWidget,
      );
      expect(find.byType(BackButtonIcon), findsOneWidget);

      if (useSystemBack) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.byType(BackButtonIcon));
      }
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(AddNewDoorsPage), findsNothing);
      expect(find.byType(SmartOpenerConnectionSuccessPage), findsNothing);
    });
  }

  testWidgets(
    'child device flow removes already-added routes and returns to command',
    (tester) async {
      await _pumpScanFlowTestApp(
        tester,
        '${DeviceCommandPage.routePath}?doorId=1&deviceId=parent-device',
        scanDuration: scanDuration,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('open-already-added-test-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('start-child-device-test-action')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Smart Opener (Built-in Wi-Fi)'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Scan'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Scan Bluetooth devices'));
      await tester.pump();
      await tester.pump(scanDuration);
      await tester.pump();

      await _tapAddDevice(tester);
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.tap(find.text('FLINX Office'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'password123');
      await _scrollToAction(tester, 'NEXT');
      await _tapAction(tester, 'NEXT');
      await tester.pumpAndSettle();

      expect(find.text('Connection successful'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Try it'));
      await tester.pumpAndSettle();

      expect(
        find.text('Device command door=1 device=parent-device'),
        findsOneWidget,
      );
      expect(find.byType(BackButtonIcon), findsNothing);
      expect(find.byType(AlreadyAddedDevicesPage), findsNothing);
      expect(find.byType(SmartOpenerConnectionSuccessPage), findsNothing);
    },
  );

  testWidgets(
    'success page share dialog opens in the screen center and closes',
    (tester) async {
      await _pumpScanFlowTestApp(
        tester,
        SmartOpenerConnectionSuccessPage.routePath,
      );
      await tester.pumpAndSettle();

      await _scrollToAction(tester, 'To share');
      await tester.tap(find.widgetWithText(FilledButton, 'To share'));
      await tester.pumpAndSettle();

      expect(find.text('SHARE DEVICE'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      final dialogCenter = tester.getCenter(find.byType(Dialog));
      expect(dialogCenter.dy, closeTo(tester.view.physicalSize.height / 2, 80));

      await tester.tap(find.widgetWithText(FilledButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'To share'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    },
  );

  testWidgets('connecting page fits a normal phone viewport', (tester) async {
    await _openChooseWifi(
      tester,
      gateway: _PendingWifiHardwareGateway(),
      scanDuration: scanDuration,
      viewSize: const Size(393, 852),
    );

    await tester.tap(find.text('FLINX Office'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'password123');
    await _scrollToAction(tester, 'NEXT');
    await _tapAction(tester, 'NEXT');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(SmartOpenerConnectingPage), findsOneWidget);
  });

  testWidgets('success page fits a normal phone viewport', (tester) async {
    await _pumpScanFlowTestApp(
      tester,
      SmartOpenerConnectionSuccessPage.routePath,
      viewSize: const Size(393, 852),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connection successful'), findsOneWidget);
    await _scrollToAction(tester, 'Try it');
    expect(find.text('Try it'), findsOneWidget);
  });
}

Future<void> _openScanResults(
  WidgetTester tester, {
  MockHardwareGateway? gateway,
  ProviderContainer? container,
  Duration scanDuration = const Duration(milliseconds: 20),
  Size viewSize = const Size(393, 1200),
}) async {
  await _pumpScanFlowTestApp(
    tester,
    SmartOpenerBleScanPage.routePath,
    gateway: gateway,
    container: container,
    scanDuration: scanDuration,
    viewSize: viewSize,
  );
  await tester.pump();
  await tester.pump(scanDuration);
  await tester.pump();
  expect(find.text('SCAN RESULTS'), findsOneWidget);
}

Future<void> _scrollToAction(WidgetTester tester, String label) async {
  final textFinder = find.text(label);
  if (textFinder.evaluate().isEmpty) {
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await tester.pump();
  }
  await tester.ensureVisible(textFinder.last);
  await tester.pump();
}

Future<void> _tapAction(WidgetTester tester, String label) async {
  final button = find.ancestor(
    of: find.text(label),
    matching: find.byType(FilledButton),
  );
  await tester.tap(button.last);
}

Future<void> _tapAddDevice(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, '+ Add');
  final topLeft = tester.getTopLeft(button.last);
  await tester.tapAt(topLeft + const Offset(4, 16));
}

Future<void> _pumpScanFlowTestApp(
  WidgetTester tester,
  String initialLocation, {
  MockHardwareGateway? gateway,
  ProviderContainer? container,
  Duration scanDuration = const Duration(seconds: 30),
  Size viewSize = const Size(393, 1200),
}) async {
  tester.view.physicalSize = viewSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _scanFlowTestApp(
      initialLocation,
      gateway: gateway,
      container: container,
      scanDuration: scanDuration,
    ),
  );
}

Future<void> _openChooseWifi(
  WidgetTester tester, {
  MockHardwareGateway? gateway,
  ProviderContainer? container,
  Duration scanDuration = const Duration(milliseconds: 20),
  Size viewSize = const Size(393, 1200),
}) async {
  await _openScanResults(
    tester,
    gateway: gateway,
    container: container,
    scanDuration: scanDuration,
    viewSize: viewSize,
  );
  await _tapAddDevice(tester);
  await tester.pump();
  await tester.pumpAndSettle();
  expect(find.text('CHOOSE WIFI'), findsOneWidget);
}

Widget _scanFlowTestApp(
  String initialLocation, {
  MockHardwareGateway? gateway,
  ProviderContainer? container,
  Duration scanDuration = const Duration(seconds: 30),
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: HomePage.routePath,
        name: HomePage.routeName,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AddNewDoorsPage.routePath,
        name: AddNewDoorsPage.routeName,
        builder: (context, state) => const AddNewDoorsPage(),
      ),
      GoRoute(
        path: AddDevicePage.routePath,
        name: AddDevicePage.routeName,
        builder: (context, state) =>
            const AddDevicePage(doorType: DoorType.garage, doorId: '1'),
      ),
      GoRoute(
        path: FBoxConnectionGuidePage.routePath,
        builder: (context, state) => const FBoxConnectionGuidePage(),
      ),
      GoRoute(
        path: UsbDongleGuidePage.routePath,
        builder: (context, state) =>
            const UsbDongleGuidePage(doorType: DoorType.garage),
      ),
      GoRoute(
        path: SmartOpenerScanGuidePage.routePath,
        builder: (context, state) => const SmartOpenerScanGuidePage(),
      ),
      GoRoute(
        path: SmartOpenerQrScanPage.routePath,
        builder: (context, state) =>
            const SmartOpenerQrScanPage(enableCamera: false),
      ),
      GoRoute(
        path: SmartOpenerBleScanPage.routePath,
        builder: (context, state) => SmartOpenerBleScanPage(
          scanDuration: scanDuration,
          targetSn: state.uri.queryParameters['targetSn'],
        ),
      ),
      GoRoute(
        path: SmartOpenerScanResultsPage.routePath,
        builder: (context, state) => const SmartOpenerScanResultsPage(),
      ),
      GoRoute(
        path: SmartOpenerDeviceNotFoundPage.routePath,
        builder: (context, state) => const SmartOpenerDeviceNotFoundPage(),
      ),
      GoRoute(
        path: SmartOpenerChooseWifiPage.routePath,
        builder: (context, state) => const SmartOpenerChooseWifiPage(),
      ),
      GoRoute(
        path: SmartOpenerConnectingPage.routePath,
        builder: (context, state) => SmartOpenerConnectingPage(
          isWifiSkipped: state.uri.queryParameters['skipWifi'] == 'true',
        ),
      ),
      GoRoute(
        path: SmartOpenerConnectionSuccessPage.routePath,
        builder: (context, state) => const SmartOpenerConnectionSuccessPage(),
      ),
      GoRoute(
        path: DeviceCommandPage.routePath,
        name: DeviceCommandPage.routeName,
        builder: (context, state) => Scaffold(
          appBar: const FlinxNavigationBar(title: 'Device command'),
          body: Column(
            children: [
              Text(
                'Device command door=${state.uri.queryParameters['doorId']} '
                'device=${state.uri.queryParameters['deviceId']}',
              ),
              FilledButton(
                key: const ValueKey<String>('open-already-added-test-action'),
                onPressed: () => context.pushNamed(
                  AlreadyAddedDevicesPage.routeName,
                  queryParameters: {
                    'doorId': state.uri.queryParameters['doorId'] ?? '',
                    'deviceId': state.uri.queryParameters['deviceId'] ?? '',
                  },
                ),
                child: const Text('Open already added'),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: AlreadyAddedDevicesPage.routePath,
        name: AlreadyAddedDevicesPage.routeName,
        builder: (context, state) => Scaffold(
          appBar: const FlinxNavigationBar(title: 'Already added'),
          body: FilledButton(
            key: const ValueKey<String>('start-child-device-test-action'),
            onPressed: () => context.pushNamed(
              AddDevicePage.routeName,
              queryParameters: {
                AddDevicePage.doorIdQueryParameter:
                    state.uri.queryParameters['doorId'] ?? '',
              },
            ),
            child: const Text('Add child device'),
          ),
        ),
      ),
    ],
  );

  final app = MaterialApp.router(
    theme: AppTheme.light(),
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }

  return ProviderScope(
    overrides: [
      addDeviceHardwareGatewayProvider.overrideWithValue(
        gateway ?? MockHardwareGateway(),
      ),
      addDeviceOnboardingRepositoryProvider.overrideWithValue(
        const _FakeAddDeviceOnboardingRepository(),
      ),
      homeDevicesProvider.overrideWith((ref) async => const <DeviceSummary>[]),
      homeScenesProvider.overrideWith((ref) async => const <HomeScene>[]),
    ],
    child: app,
  );
}

class _FakeAddDeviceOnboardingRepository
    implements AddDeviceOnboardingRepository {
  const _FakeAddDeviceOnboardingRepository();

  @override
  Future<void> validateBindingStatus({
    required String sn,
    required String requestId,
  }) async {}

  @override
  Future<OnboardingDeviceKey> fetchDeviceKey({
    required String sn,
    required String requestId,
  }) async {
    return OnboardingDeviceKey(
      sn: sn,
      aesKey: '0123456789abcdef0123456789abcdef',
      aesKeyVersion: 'test',
    );
  }

  @override
  Future<OnboardedForceDoor> addForceDoor({
    required String sn,
    String? doorId,
    required int doorType,
    required String requestId,
  }) async {
    return OnboardedForceDoor(id: 1, sn: sn, name: 'Test Door');
  }
}

class _NoDeviceHardwareGateway extends MockHardwareGateway {
  @override
  Future<void> startBleScan({
    required String requestId,
    BleScanFilter filter = const BleScanFilter(),
  }) async {}
}

class _FailingWifiHardwareGateway extends MockHardwareGateway {
  @override
  Future<WifiProvisionResult> configureWifi({
    required String requestId,
    required String deviceId,
    required String ssid,
    required String password,
  }) async {
    return WifiProvisionResult(
      requestId: requestId,
      deviceId: deviceId,
      ssid: ssid,
      success: false,
      nativeCode: 'test_wifi_failure',
    );
  }
}

class _PendingWifiHardwareGateway extends MockHardwareGateway {
  final Completer<WifiProvisionResult> _completer =
      Completer<WifiProvisionResult>();

  @override
  Future<WifiProvisionResult> configureWifi({
    required String requestId,
    required String deviceId,
    required String ssid,
    required String password,
  }) {
    return _completer.future;
  }
}
