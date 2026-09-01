import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/features/add_device/domain/entities/onboarded_force_door.dart';
import 'package:flinx/features/add_device/domain/entities/onboarding_device_key.dart';
import 'package:flinx/features/add_device/domain/repositories/add_device_onboarding_repository.dart';
import 'package:flinx/features/add_device/presentation/pages/smart_opener_qr_scan_page.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MobileScannerPlatform originalScannerPlatform;

  setUp(() {
    originalScannerPlatform = MobileScannerPlatform.instance;
  });

  tearDown(() {
    MobileScannerPlatform.instance = originalScannerPlatform;
  });

  testWidgets(
    'opens settings from the camera permission dialog and restarts scanning on return',
    (tester) async {
      final scannerPlatform = _CameraPermissionScannerPlatform();
      final gateway = _SettingsTrackingGateway();
      MobileScannerPlatform.instance = scannerPlatform;

      await _pumpQrScannerPage(tester, gateway);

      expect(
        find.byKey(SmartOpenerQrScanPageKeys.cameraPermissionDialog),
        findsOneWidget,
      );
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.byTooltip('Scan Bluetooth devices'), findsOneWidget);

      await tester.tap(
        find.byKey(
          SmartOpenerQrScanPageKeys.cameraPermissionDialogSettingsAction,
        ),
      );
      await tester.pumpAndSettle();

      expect(gateway.openAppSettingsRequestIds, hasLength(1));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      scannerPlatform.cameraGranted = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(scannerPlatform.startCalls, 2);
      expect(
        find.byKey(SmartOpenerQrScanPageKeys.cameraPermissionDialog),
        findsNothing,
      );
    },
  );

  testWidgets(
    'keeps gallery and Bluetooth scanning available after dismissing permission guidance',
    (tester) async {
      MobileScannerPlatform.instance = _CameraPermissionScannerPlatform();

      await _pumpQrScannerPage(tester, _SettingsTrackingGateway());

      await tester.tap(
        find.byKey(
          SmartOpenerQrScanPageKeys.cameraPermissionDialogCancelAction,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gallery'), findsOneWidget);
      expect(find.byTooltip('Scan Bluetooth devices'), findsOneWidget);
      expect(
        find.byKey(
          SmartOpenerQrScanPageKeys.cameraPermissionErrorSettingsAction,
        ),
        findsOneWidget,
      );
    },
  );
}

Future<void> _pumpQrScannerPage(
  WidgetTester tester,
  MockHardwareGateway gateway,
) async {
  final router = GoRouter(
    initialLocation: SmartOpenerQrScanPage.routePath,
    routes: [
      GoRoute(
        path: SmartOpenerQrScanPage.routePath,
        builder: (context, state) => const SmartOpenerQrScanPage(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        addDeviceHardwareGatewayProvider.overrideWithValue(gateway),
        addDeviceOnboardingRepositoryProvider.overrideWithValue(
          const _NoopAddDeviceOnboardingRepository(),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _CameraPermissionScannerPlatform extends MobileScannerPlatform {
  var cameraGranted = false;
  var startCalls = 0;

  @override
  Stream<BarcodeCapture?> get barcodesStream =>
      const Stream<BarcodeCapture?>.empty();

  @override
  Stream<TorchState> get torchStateStream => const Stream<TorchState>.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream<double>.empty();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    startCalls += 1;
    if (!cameraGranted) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );
    }
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(200, 200),
      numberOfCameras: 1,
    );
  }

  @override
  Widget buildCameraView() => const SizedBox.expand();

  @override
  Future<void> stop() async {}

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> dispose() async {}
}

class _SettingsTrackingGateway extends MockHardwareGateway {
  final List<String> openAppSettingsRequestIds = <String>[];

  @override
  Future<void> openAppSettings({required String requestId}) async {
    openAppSettingsRequestIds.add(requestId);
  }
}

class _NoopAddDeviceOnboardingRepository
    implements AddDeviceOnboardingRepository {
  const _NoopAddDeviceOnboardingRepository();

  @override
  Future<OnboardedForceDoor> addForceDoor({
    required String sn,
    String? doorId,
    int? sceneId,
    required int doorType,
    required String requestId,
  }) async => OnboardedForceDoor(id: 1, sn: sn);

  @override
  Future<OnboardingDeviceKey> fetchDeviceKey({
    required String sn,
    required String requestId,
  }) async => OnboardingDeviceKey(
    sn: sn,
    aesKey: '0123456789abcdef0123456789abcdef',
    aesKeyVersion: 'test',
  );

  @override
  Future<void> validateBindingStatus({
    required String sn,
    required String requestId,
  }) async {}
}
