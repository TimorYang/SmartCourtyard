import 'dart:async';

import 'package:flinx/features/add_device/application/add_device_controller.dart';
import 'package:flinx/features/add_device/application/f_box_wiring_test_controller.dart';
import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/features/add_device/presentation/navigation/f_box_wiring_test_route.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/domain/entities/door_device.dart';
import 'package:flinx/features/device_control/domain/entities/f_box_control_mode.dart';
import 'package:flinx/features/device_control/domain/repositories/door_control_mode_repository.dart';
import 'package:flinx/features/device_control/domain/use_cases/update_door_control_mode_use_case.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sends PB and O/S/C actions through the local BLE gateway', () async {
    final gateway = _RecordingHardwareGateway();
    final container = _createContainer(gateway);
    addTearDown(container.dispose);
    final controller = container.read(
      fBoxWiringTestControllerProvider.notifier,
    );
    const routeData = FBoxWiringTestRouteData(
      doorId: '42',
      deviceId: 'fbox-device',
      onboardingFlowId: 'flow-1',
    );

    for (final action in FBoxWiringTestAction.values) {
      await controller.send(routeData: routeData, action: action);
    }

    expect(gateway.commands, [
      DoorCommand.pb,
      DoorCommand.close,
      DoorCommand.stop,
      DoorCommand.open,
    ]);
    expect(gateway.deviceIds, [
      'fbox-device',
      'fbox-device',
      'fbox-device',
      'fbox-device',
    ]);
    expect(gateway.requestIds, hasLength(4));
    expect(gateway.requestIds.toSet(), hasLength(4));
    expect(container.read(fBoxWiringTestControllerProvider).hasTested, isTrue);
  });

  test(
    'does not send while the selected onboarding device is disconnected',
    () async {
      final gateway = _RecordingHardwareGateway();
      final container = _createContainer(gateway, connected: false);
      addTearDown(container.dispose);
      final controller = container.read(
        fBoxWiringTestControllerProvider.notifier,
      );

      await controller.send(
        routeData: const FBoxWiringTestRouteData(deviceId: 'fbox-device'),
        action: FBoxWiringTestAction.pb,
      );

      expect(gateway.commands, isEmpty);
      expect(
        container.read(fBoxWiringTestControllerProvider).error,
        FBoxWiringTestError.noConnectedDevice,
      );
    },
  );

  test('keeps the tested state and reports a rejected command', () async {
    final gateway = _RecordingHardwareGateway(accepted: false);
    final container = _createContainer(gateway);
    addTearDown(container.dispose);
    final controller = container.read(
      fBoxWiringTestControllerProvider.notifier,
    );

    await controller.send(
      routeData: const FBoxWiringTestRouteData(deviceId: 'fbox-device'),
      action: FBoxWiringTestAction.stop,
    );

    final state = container.read(fBoxWiringTestControllerProvider);
    expect(state.status, FBoxWiringTestStatus.rejected);
    expect(state.error, FBoxWiringTestError.commandRejected);
    expect(state.hasTested, isFalse);
  });

  test('ignores a second action while a command is pending', () async {
    final gateway = _RecordingHardwareGateway();
    final pendingResult = Completer<CommandResult>();
    gateway.pendingResult = pendingResult;
    final container = _createContainer(gateway);
    addTearDown(container.dispose);
    final subscription = container.listen(
      fBoxWiringTestControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(
      fBoxWiringTestControllerProvider.notifier,
    );
    const routeData = FBoxWiringTestRouteData(deviceId: 'fbox-device');

    final first = controller.send(
      routeData: routeData,
      action: FBoxWiringTestAction.pb,
    );
    await Future<void>.delayed(Duration.zero);
    await controller.send(
      routeData: routeData,
      action: FBoxWiringTestAction.open,
    );

    expect(gateway.commands, [DoorCommand.pb]);
    pendingResult.complete(
      const CommandResult(
        requestId: 'request',
        deviceId: 'fbox-device',
        command: DoorCommand.pb,
        accepted: true,
      ),
    );
    await first;
    expect(container.read(fBoxWiringTestControllerProvider).hasTested, isTrue);
  });

  test('reports PB and OSC modes with their API values', () async {
    final gateway = _RecordingHardwareGateway();
    final repository = _RecordingDoorControlModeRepository();
    final container = _createContainer(
      gateway,
      controlModeRepository: repository,
    );
    addTearDown(container.dispose);
    final controller = container.read(
      fBoxWiringTestControllerProvider.notifier,
    );
    const routeData = FBoxWiringTestRouteData(
      deviceId: 'fbox-device',
      onboardingFlowId: 'flow-control-mode',
    );

    expect(
      await controller.updateControlMode(
        routeData: routeData,
        mode: FBoxControlMode.pb,
      ),
      isTrue,
    );
    expect(
      await controller.updateControlMode(
        routeData: routeData,
        mode: FBoxControlMode.osc,
      ),
      isTrue,
    );

    expect(repository.calls.map((call) => call.sn), [
      'SN-ONBOARDING',
      'SN-ONBOARDING',
    ]);
    expect(repository.calls.map((call) => call.mode), [
      FBoxControlMode.pb,
      FBoxControlMode.osc,
    ]);
    expect(repository.calls.map((call) => call.requestId), hasLength(2));
    expect(
      repository.calls.map((call) => call.requestId).toSet(),
      hasLength(2),
    );
  });

  test(
    'resolves the serial number from the device-command door device',
    () async {
      final repository = _RecordingDoorControlModeRepository();
      final container = _createContainer(
        _RecordingHardwareGateway(),
        controlModeRepository: repository,
        deviceCommandState: const DeviceCommandState(
          selectedDeviceId: 'door-device',
          doorDevices: [
            DoorDevice(
              deviceId: 'door-device',
              sn: 'SN-DEVICE-COMMAND',
              deviceType: 'fbox',
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      final controller = container.read(
        fBoxWiringTestControllerProvider.notifier,
      );

      expect(
        await controller.updateControlMode(
          routeData: const FBoxWiringTestRouteData(
            deviceId: 'door-device',
            entryPoint: FBoxWiringTestEntryPoint.deviceCommand,
          ),
          mode: FBoxControlMode.osc,
        ),
        isTrue,
      );

      expect(repository.calls.single.sn, 'SN-DEVICE-COMMAND');
      expect(repository.calls.single.mode, FBoxControlMode.osc);
    },
  );

  test(
    'does not report when the onboarding serial number is missing',
    () async {
      final repository = _RecordingDoorControlModeRepository();
      final container = _createContainer(
        _RecordingHardwareGateway(),
        sn: null,
        controlModeRepository: repository,
      );
      addTearDown(container.dispose);
      final controller = container.read(
        fBoxWiringTestControllerProvider.notifier,
      );

      expect(
        await controller.updateControlMode(
          routeData: const FBoxWiringTestRouteData(deviceId: 'fbox-device'),
          mode: FBoxControlMode.pb,
        ),
        isFalse,
      );

      final state = container.read(fBoxWiringTestControllerProvider);
      expect(repository.calls, isEmpty);
      expect(state.status, FBoxWiringTestStatus.failed);
      expect(state.error, FBoxWiringTestError.controlModeReportFailed);
    },
  );

  test('blocks duplicate control-mode reports while pending', () async {
    final repository = _RecordingDoorControlModeRepository();
    final pendingResult = Completer<void>();
    repository.pendingResult = pendingResult;
    final container = _createContainer(
      _RecordingHardwareGateway(),
      controlModeRepository: repository,
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      fBoxWiringTestControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(
      fBoxWiringTestControllerProvider.notifier,
    );
    const routeData = FBoxWiringTestRouteData(deviceId: 'fbox-device');

    final first = controller.updateControlMode(
      routeData: routeData,
      mode: FBoxControlMode.pb,
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      await controller.updateControlMode(
        routeData: routeData,
        mode: FBoxControlMode.osc,
      ),
      isFalse,
    );
    expect(repository.calls, hasLength(1));
    expect(
      container.read(fBoxWiringTestControllerProvider).isReportingControlMode,
      isTrue,
    );

    pendingResult.complete();
    expect(await first, isTrue);
  });

  test('allows retry after a failed control-mode report', () async {
    final repository = _RecordingDoorControlModeRepository()..failure = true;
    final container = _createContainer(
      _RecordingHardwareGateway(),
      controlModeRepository: repository,
    );
    addTearDown(container.dispose);
    final controller = container.read(
      fBoxWiringTestControllerProvider.notifier,
    );
    const routeData = FBoxWiringTestRouteData(deviceId: 'fbox-device');

    expect(
      await controller.updateControlMode(
        routeData: routeData,
        mode: FBoxControlMode.pb,
      ),
      isFalse,
    );
    repository.failure = false;
    expect(
      await controller.updateControlMode(
        routeData: routeData,
        mode: FBoxControlMode.pb,
      ),
      isTrue,
    );

    expect(repository.calls, hasLength(2));
    expect(
      container.read(fBoxWiringTestControllerProvider).status,
      FBoxWiringTestStatus.succeeded,
    );
  });
}

ProviderContainer _createContainer(
  _RecordingHardwareGateway gateway, {
  bool connected = true,
  String? sn = 'SN-ONBOARDING',
  DoorControlModeRepository? controlModeRepository,
  DeviceCommandState? deviceCommandState,
}) {
  final device = BleDevice(
    requestId: 'scan-request',
    scanSessionId: 'scan-session',
    id: 'fbox-device',
    rssi: -40,
    seenAtMillis: 1,
    sn: sn,
  );
  final state = AddDeviceState.initial().copyWith(
    selectedDevice: device,
    connectionStates: {
      device.id: connected
          ? BleConnectionState.connected
          : BleConnectionState.disconnected,
    },
  );
  return ProviderContainer(
    overrides: [
      addDeviceControllerProvider.overrideWith(
        () => _AddDeviceController(state),
      ),
      deviceCommandHardwareGatewayProvider.overrideWithValue(gateway),
      updateDoorControlModeUseCaseProvider.overrideWithValue(
        UpdateDoorControlModeUseCase(
          repository:
              controlModeRepository ?? _RecordingDoorControlModeRepository(),
        ),
      ),
      if (deviceCommandState != null)
        deviceCommandControllerProvider.overrideWith(
          () => _DeviceCommandController(deviceCommandState),
        ),
    ],
  );
}

class _AddDeviceController extends AddDeviceController {
  _AddDeviceController(this.initialState);

  final AddDeviceState initialState;

  @override
  AddDeviceState build() => initialState;
}

class _DeviceCommandController extends DeviceCommandController {
  _DeviceCommandController(this.initialState);

  final DeviceCommandState initialState;

  @override
  DeviceCommandState build() => initialState;
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
  _RecordingHardwareGateway({this.accepted = true});

  final bool accepted;
  final List<DoorCommand> commands = <DoorCommand>[];
  final List<String> deviceIds = <String>[];
  final List<String> requestIds = <String>[];
  Completer<CommandResult>? pendingResult;

  @override
  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  }) {
    commands.add(command);
    deviceIds.add(deviceId);
    requestIds.add(requestId);
    final result = pendingResult;
    if (result != null) {
      return result.future;
    }
    return Future.value(
      CommandResult(
        requestId: requestId,
        deviceId: deviceId,
        command: command,
        accepted: accepted,
      ),
    );
  }
}
