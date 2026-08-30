import 'dart:async';

import 'package:flinx/features/add_device/application/add_device_controller.dart';
import 'package:flinx/features/add_device/application/f_box_wiring_test_controller.dart';
import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/features/add_device/presentation/navigation/f_box_wiring_test_route.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
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
}

ProviderContainer _createContainer(
  _RecordingHardwareGateway gateway, {
  bool connected = true,
}) {
  final device = BleDevice(
    requestId: 'scan-request',
    scanSessionId: 'scan-session',
    id: 'fbox-device',
    rssi: -40,
    seenAtMillis: 1,
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
    ],
  );
}

class _AddDeviceController extends AddDeviceController {
  _AddDeviceController(this.initialState);

  final AddDeviceState initialState;

  @override
  AddDeviceState build() => initialState;
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
