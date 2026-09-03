import 'dart:async';

import 'package:flinx/app/theme/app_design_tokens.dart';
import 'package:flinx/features/add_device/application/add_device_controller.dart';
import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/features/add_device/presentation/pages/f_box_wiring_test_page.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/domain/entities/f_box_control_mode.dart';
import 'package:flinx/features/device_control/domain/repositories/door_control_mode_repository.dart';
import 'package:flinx/features/device_control/domain/use_cases/update_door_control_mode_use_case.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flinx/shared/widgets/flinx_door_command_button.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the PB wiring state and records a local test action', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();
    await _pumpPage(tester, gateway: gateway);

    expect(find.text('Test'), findsOneWidget);
    expect(find.text('PB wiring'), findsOneWidget);
    expect(find.text('O/S/C wiring'), findsOneWidget);
    expect(find.byKey(const Key('fBoxWiringTestPbControl')), findsOneWidget);
    expect(find.byKey(const Key('fBoxWiringTestOpenControl')), findsNothing);
    expect(find.text('door operates normally'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
    expect(find.byTooltip('Add'), findsOneWidget);

    expect(_statusColor(tester), AppColors.fBoxWiringTestStatusPending);
    await tester.tap(find.byKey(const Key('fBoxWiringTestPbControl')));
    await tester.pumpAndSettle();
    expect(_statusColor(tester), AppColors.brandPrimary);
    expect(gateway.commands, [DoorCommand.pb]);
  });

  testWidgets('switches to O/S/C controls and leaves NEXT local', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();
    await _pumpPage(tester, gateway: gateway);

    await tester.tap(find.byKey(const Key('fBoxWiringTestOscSegment')));
    await tester.pump();

    expect(find.byKey(const Key('fBoxWiringTestPbControl')), findsNothing);
    expect(find.byKey(const Key('fBoxWiringTestOpenControl')), findsOneWidget);
    expect(find.byKey(const Key('fBoxWiringTestStopControl')), findsOneWidget);
    expect(find.byKey(const Key('fBoxWiringTestCloseControl')), findsOneWidget);
    expect(find.byTooltip('Close door'), findsOneWidget);
    expect(find.byTooltip('Stop door'), findsOneWidget);
    expect(find.byTooltip('Open door'), findsOneWidget);

    final closeControl = tester.widget<FlinxDoorCommandButton>(
      find.descendant(
        of: find.byKey(const Key('fBoxWiringTestOpenControl')),
        matching: find.byType(FlinxDoorCommandButton),
      ),
    );
    final stopControl = tester.widget<FlinxDoorCommandButton>(
      find.descendant(
        of: find.byKey(const Key('fBoxWiringTestStopControl')),
        matching: find.byType(FlinxDoorCommandButton),
      ),
    );
    final openControl = tester.widget<FlinxDoorCommandButton>(
      find.descendant(
        of: find.byKey(const Key('fBoxWiringTestCloseControl')),
        matching: find.byType(FlinxDoorCommandButton),
      ),
    );
    expect(closeControl.icon, Icons.keyboard_arrow_down);
    expect(stopControl.icon, Icons.pause);
    expect(openControl.icon, Icons.keyboard_arrow_up);
    expect(
      tester.getSize(find.byKey(const Key('fBoxWiringTestOpenControl'))),
      const Size(52, 52),
    );
    expect(
      tester.getSize(find.byKey(const Key('fBoxWiringTestStopControl'))),
      const Size(52, 52),
    );
    expect(
      tester.getSize(find.byKey(const Key('fBoxWiringTestCloseControl'))),
      const Size(52, 52),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('fBoxWiringTestStopControl'))).dx -
          tester
              .getTopRight(find.byKey(const Key('fBoxWiringTestOpenControl')))
              .dx,
      closeTo(40, 0.01),
    );
    expect(
      tester
              .getTopLeft(find.byKey(const Key('fBoxWiringTestCloseControl')))
              .dx -
          tester
              .getTopRight(find.byKey(const Key('fBoxWiringTestStopControl')))
              .dx,
      closeTo(40, 0.01),
    );

    await tester.tap(find.byKey(const Key('fBoxWiringTestStopControl')));
    await tester.pumpAndSettle();
    expect(_statusColor(tester), AppColors.brandPrimary);
    expect(gateway.commands, [DoorCommand.stop]);

    final nextButton = find.byKey(const Key('fBoxWiringTestNextButton'));
    expect(tester.widget<FilledButton>(nextButton).onPressed, isNotNull);
  });

  testWidgets('does not show a connection prompt on the wiring test page', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();
    await _pumpPage(
      tester,
      gateway: gateway,
      connectionState: BleConnectionState.disconnected,
    );

    await tester.tap(find.byKey(const Key('fBoxWiringTestPbControl')));
    await tester.pumpAndSettle();

    expect(gateway.commands, isEmpty);
    expect(
      find.text('Connect the F-box over Bluetooth before testing.'),
      findsNothing,
    );
  });

  testWidgets('renders the Chinese copy', (tester) async {
    await _pumpPage(tester, locale: const Locale('zh'));

    expect(find.text('测试'), findsOneWidget);
    expect(find.text('PB 接线'), findsOneWidget);
    expect(find.text('门体正常运行'), findsOneWidget);
    expect(find.byTooltip('添加'), findsOneWidget);
  });

  testWidgets('uses the renamed PB asset and reference geometry on mobile', (
    tester,
  ) async {
    await _pumpPage(tester, surfaceSize: const Size(375, 812));

    final image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('fBoxWiringTestPbControl')),
        matching: find.byType(Image),
      ),
    );
    expect(
      (image.image as AssetImage).assetName,
      FBoxWiringTestAssetPaths.pbControl,
    );
    expect(
      tester.getSize(find.byKey(const Key('fBoxWiringTestSegmentedControl'))),
      const Size(224, 32),
    );
    expect(
      tester.getSize(find.byKey(const Key('fBoxWiringTestPbControl'))),
      const Size(170, 170),
    );
    expect(
      tester.getSize(find.byKey(const Key('fBoxWiringTestNextButton'))),
      const Size(335, 52),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('centers and constrains content on a wide window', (
    tester,
  ) async {
    await _pumpPage(tester, surfaceSize: const Size(1024, 768));

    final segment = find.byKey(const Key('fBoxWiringTestSegmentedControl'));
    expect(tester.getSize(segment), const Size(224, 32));
    expect(
      tester.getSize(find.byKey(const Key('fBoxWiringTestNextButton'))),
      const Size(640, 52),
    );
    expect(tester.getTopLeft(segment).dx, closeTo(192, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports the selected PB or OSC mode and allows retry', (
    tester,
  ) async {
    final repository = _RecordingDoorControlModeRepository()..failure = true;
    await _pumpPage(tester, controlModeRepository: repository);

    final nextButton = find.byKey(const Key('fBoxWiringTestNextButton'));
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(repository.calls.single.mode, FBoxControlMode.pb);
    expect(
      find.text('Unable to save the control mode. Please try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('fBoxWiringTestNextButton')),
          )
          .onPressed,
      isNotNull,
    );

    final oscSegment = find.byKey(const Key('fBoxWiringTestOscSegment'));
    await tester.ensureVisible(oscSegment);
    await tester.tap(oscSegment);
    await tester.pump();
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(repository.calls, hasLength(2));
    expect(repository.calls.last.mode, FBoxControlMode.osc);
  });

  testWidgets('disables NEXT and shows progress while reporting', (
    tester,
  ) async {
    final repository = _RecordingDoorControlModeRepository();
    final pendingResult = Completer<void>();
    repository.pendingResult = pendingResult;
    await _pumpPage(tester, controlModeRepository: repository);

    final nextButton = find.byKey(const Key('fBoxWiringTestNextButton'));
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pump();

    expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);
    expect(
      find.descendant(
        of: nextButton,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    pendingResult.completeError(StateError('control mode update failed'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(nextButton).onPressed, isNotNull);
  });

  testWidgets('allows scrolling on a short window without overflow', (
    tester,
  ) async {
    await _pumpPage(tester, surfaceSize: const Size(375, 400));

    expect(tester.takeException(), isNull);
    final nextButton = find.byKey(const Key('fBoxWiringTestNextButton'));
    await tester.ensureVisible(nextButton);
    expect(tester.takeException(), isNull);
  });
}

Color _statusColor(WidgetTester tester) {
  final indicator = tester.widget<Container>(
    find.byKey(const Key('fBoxWiringTestStatusIndicator')),
  );
  return (indicator.decoration! as BoxDecoration).color!;
}

Future<void> _pumpPage(
  WidgetTester tester, {
  Locale? locale,
  Size? surfaceSize,
  _RecordingHardwareGateway? gateway,
  DoorControlModeRepository? controlModeRepository,
  BleConnectionState connectionState = BleConnectionState.connected,
}) async {
  if (surfaceSize != null) {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  final selectedDevice = BleDevice(
    requestId: 'test-request',
    scanSessionId: 'test-session',
    id: 'fbox-native-device',
    rssi: -30,
    seenAtMillis: 1,
    sn: 'SN-FBOX-001',
  );
  final initialState = AddDeviceState.initial().copyWith(
    selectedDevice: selectedDevice,
    connectionStates: {selectedDevice.id: connectionState},
    onboardingDeviceType: 'fbox',
  );
  final hardwareGateway = gateway ?? _RecordingHardwareGateway();
  final modeRepository =
      controlModeRepository ?? _RecordingDoorControlModeRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        addDeviceControllerProvider.overrideWith(
          () => _FBoxAddDeviceController(initialState),
        ),
        deviceCommandHardwareGatewayProvider.overrideWithValue(hardwareGateway),
        updateDoorControlModeUseCaseProvider.overrideWithValue(
          UpdateDoorControlModeUseCase(repository: modeRepository),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FBoxWiringTestPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FBoxAddDeviceController extends AddDeviceController {
  _FBoxAddDeviceController(this.initialState);

  final AddDeviceState initialState;

  @override
  AddDeviceState build() => initialState;
}

class _RecordingDoorControlModeRepository implements DoorControlModeRepository {
  final List<_ControlModeCall> calls = <_ControlModeCall>[];
  Completer<void>? pendingResult;
  bool failure = false;

  @override
  Future<void> updateControlMode({
    required String sn,
    required FBoxControlMode mode,
    required String requestId,
  }) {
    calls.add(_ControlModeCall(sn: sn, mode: mode, requestId: requestId));
    final pending = pendingResult;
    if (pending != null) {
      return pending.future;
    }
    if (failure) {
      return Future<void>.error(StateError('control mode update failed'));
    }
    return Future<void>.value();
  }
}

class _ControlModeCall {
  const _ControlModeCall({
    required this.sn,
    required this.mode,
    required this.requestId,
  });

  final String sn;
  final FBoxControlMode mode;
  final String requestId;
}

class _RecordingHardwareGateway extends MockHardwareGateway {
  final List<DoorCommand> commands = <DoorCommand>[];

  @override
  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  }) async {
    commands.add(command);
    return super.sendDoorCommand(
      requestId: requestId,
      deviceId: deviceId,
      command: command,
    );
  }
}
