import 'package:flinx/features/add_device/application/add_device_controller.dart';
import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/features/add_device/domain/entities/onboarded_force_door.dart';
import 'package:flinx/features/add_device/presentation/navigation/f_box_wiring_test_route.dart';
import 'package:flinx/features/add_device/presentation/pages/f_box_wiring_test_page.dart';
import 'package:flinx/features/add_device/presentation/pages/smart_opener_connection_success_page.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/presentation/pages/device_command_page.dart';
import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/features/home/application/door_share_controller.dart';
import 'package:flinx/features/home/domain/entities/home_door_cover_image.dart';
import 'package:flinx/features/home/domain/entities/home_scene.dart';
import 'package:flinx/features/home/domain/entities/door_share.dart';
import 'package:flinx/features/home/domain/repositories/home_door_repository.dart';
import 'package:flinx/features/home/presentation/pages/device_share_page.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('hides name and scene controls for a child device', (
    tester,
  ) async {
    await _pumpSuccessPage(tester, onboardingDoorId: 'parent-door');

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Select scene'), findsNothing);
  });

  testWidgets('shows only the name control when a scene is provided', (
    tester,
  ) async {
    await _pumpSuccessPage(tester, onboardingSceneId: 3);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Select scene'), findsNothing);
  });

  testWidgets('shows name and scene controls for a serial-number flow', (
    tester,
  ) async {
    await _pumpSuccessPage(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Select scene'), findsOneWidget);
  });

  testWidgets('saves a changed name after the field loses focus', (
    tester,
  ) async {
    final repository = _RecordingHomeDoorRepository();
    await _pumpSuccessPage(tester, repository: repository);

    await tester.enterText(find.byType(TextField), 'New door name');
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(repository.renamedName, 'New door name');
    expect(repository.renamedDoorId, 42);
  });

  testWidgets('selecting a scene from the bottom sheet moves the door', (
    tester,
  ) async {
    final repository = _RecordingHomeDoorRepository();
    await _pumpSuccessPage(
      tester,
      repository: repository,
      scenes: const [
        HomeScene(id: 3, name: 'Office', doorCount: 0, isDefault: false),
      ],
    );

    await tester.tap(find.text('Select scene'));
    await tester.pumpAndSettle();
    expect(find.text('Office'), findsOneWidget);

    await tester.tap(find.text('Office'));
    await tester.pumpAndSettle();

    expect(repository.movedDoorId, 42);
    expect(repository.movedSceneId, 3);
  });

  testWidgets('share now opens the share page for the onboarded door', (
    tester,
  ) async {
    final state = AddDeviceState.initial().copyWith(
      onboardedDoor: const OnboardedForceDoor(
        id: 42,
        sn: 'SN-001',
        name: 'Original name',
      ),
    );
    final router = GoRouter(
      initialLocation: '/success',
      routes: [
        GoRoute(
          path: '/success',
          builder: (context, state) => const SmartOpenerConnectionSuccessPage(),
        ),
        GoRoute(
          path: DeviceSharePage.routePath,
          name: DeviceSharePage.routeName,
          builder: (context, state) {
            final routeData = state.extra! as DeviceShareCreateRouteData;
            return DeviceSharePage(
              doorId: routeData.doorId,
              initialAddress: routeData.initialAddress,
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addDeviceControllerProvider.overrideWith(
            () => _SuccessPageController(state),
          ),
          homeDoorRepositoryProvider.overrideWithValue(
            _RecordingHomeDoorRepository(),
          ),
          homeScenesProvider.overrideWith((ref) async => const []),
          homeDevicesProvider.overrideWith((ref) async => const []),
          doorShareCapabilitiesProvider(
            42,
          ).overrideWith((ref) async => ShareCapability.values),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('To share'));
    await tester.pumpAndSettle();
    expect(find.text('Share now'), findsOneWidget);

    const address = 'shared.user@example.com';
    await tester.enterText(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      ),
      address,
    );
    await tester.tap(find.text('Share now'));
    await tester.pumpAndSettle();

    final sharePage = tester.widget<DeviceSharePage>(
      find.byType(DeviceSharePage),
    );
    expect(sharePage.doorId, 42);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      address,
    );
  });

  testWidgets('F-Box Try it opens wiring test before device command', (
    tester,
  ) async {
    final selectedDevice = BleDevice(
      requestId: 'request-1',
      scanSessionId: 'scan-1',
      id: 'fbox-native-device',
      name: 'F-Box',
      sn: 'FBOX-001',
      rssi: -42,
      seenAtMillis: 1,
    );
    final state = AddDeviceState.initial().copyWith(
      onboardedDoor: const OnboardedForceDoor(
        id: 42,
        sn: 'SN-001',
        name: 'F-Box door',
      ),
      selectedDevice: selectedDevice,
      connectionStates: {selectedDevice.id: BleConnectionState.connected},
      onboardingDeviceType: 'fbox',
      onboardingFlowId: 'flow/1',
    );
    final router = GoRouter(
      initialLocation: SmartOpenerConnectionSuccessPage.routePath,
      routes: [
        GoRoute(
          path: SmartOpenerConnectionSuccessPage.routePath,
          name: SmartOpenerConnectionSuccessPage.routeName,
          builder: (context, state) => const SmartOpenerConnectionSuccessPage(),
        ),
        GoRoute(
          path: FBoxWiringTestRoute.routePath,
          name: FBoxWiringTestRoute.routeName,
          builder: (context, state) => FBoxWiringTestPage(
            routeData: FBoxWiringTestRoute.fromQueryParameters(
              state.uri.queryParameters,
            ),
          ),
        ),
        GoRoute(
          path: DeviceCommandPage.routePath,
          name: DeviceCommandPage.routeName,
          builder: (context, state) =>
              const Scaffold(body: Text('Device command')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addDeviceControllerProvider.overrideWith(
            () => _SuccessPageController(state),
          ),
          homeScenesProvider.overrideWith((ref) async => const []),
          homeDevicesProvider.overrideWith((ref) async => const []),
          deviceCommandHardwareGatewayProvider.overrideWithValue(
            MockHardwareGateway(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SmartOpenerConnectionSuccessPage), findsOneWidget);
    expect(find.text('Connection successful'), findsOneWidget);
    if (find.text('Try it').evaluate().isEmpty) {
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
      await tester.pump();
    }
    expect(find.text('Try it'), findsOneWidget);
    await tester.ensureVisible(find.text('Try it'));
    await tester.tap(find.text('Try it'));
    await tester.pumpAndSettle();

    expect(find.byType(FBoxWiringTestPage), findsOneWidget);
    final wiringPage = tester.widget<FBoxWiringTestPage>(
      find.byType(FBoxWiringTestPage),
    );
    expect(wiringPage.routeData.doorId, '42');
    expect(wiringPage.routeData.deviceId, selectedDevice.id);
    expect(wiringPage.routeData.onboardingFlowId, 'flow/1');
    expect(wiringPage.routeData.entryPoint, FBoxWiringTestEntryPoint.tryIt);
  });
}

Future<void> _pumpSuccessPage(
  WidgetTester tester, {
  String? onboardingDoorId,
  int? onboardingSceneId,
  _RecordingHomeDoorRepository? repository,
  List<HomeScene> scenes = const [],
}) async {
  final homeRepository = repository ?? _RecordingHomeDoorRepository();
  final state = AddDeviceState.initial().copyWith(
    onboardedDoor: const OnboardedForceDoor(
      id: 42,
      sn: 'SN-001',
      name: 'Original name',
    ),
    onboardingDoorId: onboardingDoorId,
    clearOnboardingDoorId: onboardingDoorId == null,
    onboardingSceneId: onboardingSceneId,
    clearOnboardingSceneId: onboardingSceneId == null,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        addDeviceControllerProvider.overrideWith(
          () => _SuccessPageController(state),
        ),
        homeDoorRepositoryProvider.overrideWithValue(homeRepository),
        homeScenesProvider.overrideWith((ref) async => scenes),
        homeDevicesProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SmartOpenerConnectionSuccessPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _SuccessPageController extends AddDeviceController {
  _SuccessPageController(this.initialState);

  final AddDeviceState initialState;

  @override
  AddDeviceState build() => initialState;

  @override
  void logSuccessPageEntered() {}

  @override
  void logDeviceDetailNavigation() {}
}

class _RecordingHomeDoorRepository implements HomeDoorRepository {
  int? renamedDoorId;
  String? renamedName;
  int? movedDoorId;
  int? movedSceneId;

  @override
  Future<List<DeviceSummary>> fetchDoors({
    required int sceneId,
    required String requestId,
  }) async => const [];

  @override
  Future<void> topDoor({
    required int doorId,
    required String requestId,
  }) async {}

  @override
  Future<void> unbindDoor({
    required int doorId,
    required String requestId,
  }) async {}

  @override
  Future<void> resetDoorCover({
    required int doorId,
    required String requestId,
  }) async {}

  @override
  Future<void> updateDoorCover({
    required int doorId,
    required HomeDoorCoverImage image,
    required String requestId,
  }) async {}

  @override
  Future<void> renameDoor({
    required int doorId,
    required String name,
    required String requestId,
  }) async {
    renamedDoorId = doorId;
    renamedName = name;
  }

  @override
  Future<void> moveDoorToScene({
    required int doorId,
    required int sceneId,
    required String requestId,
  }) async {
    movedDoorId = doorId;
    movedSceneId = sceneId;
  }
}
