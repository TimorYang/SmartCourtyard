import 'dart:async';

import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/presentation/pages/device_command_page.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders garage door controls and sends primary commands', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(tester, gateway);

    expect(find.text('Garage door'), findsOneWidget);
    expect(find.text('Operated cycles'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('LED'), findsOneWidget);
    expect(find.text('Auto close'), findsOneWidget);
    expect(find.text('Partial open'), findsOneWidget);
    expect(find.text('More setting'), findsOneWidget);

    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.open);
    expect(find.text('开门指令已发送（0x1001）。'), findsOneWidget);

    await tester.tap(find.byTooltip('Stop'));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.stop);
    expect(find.text('暂停指令已发送（0x1003）。'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.close);
    expect(find.text('关门指令已发送（0x1002）。'), findsOneWidget);
  });

  testWidgets('quick actions send light, partial open, and query requests', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(tester, gateway);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.lightOn);
    expect(find.text('开灯指令已发送（0x1005）。'), findsOneWidget);

    await tester.ensureVisible(find.text('Partial open'));
    await tester.tap(find.text('Partial open'));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.partialOpen);
    expect(find.text('半开门指令已发送（0x1004）。'), findsOneWidget);

    await tester.ensureVisible(find.text('More setting'));
    await tester.tap(find.text('More setting'));
    await tester.pumpAndSettle();

    expect(gateway.queryCount, 1);
    expect(find.text('已查询到 2/2 个遥控器。'), findsOneWidget);
  });

  testWidgets('shows pending state while a command is in progress', (
    tester,
  ) async {
    final gateway = _PendingCommandGateway();

    await _pumpDevicePage(tester, gateway);

    await tester.tap(find.byTooltip('Open'));
    await tester.pump();

    expect(find.text('正在发送开门指令（0x1001）...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    for (final button in tester.widgetList<IconButton>(
      find.byType(IconButton),
    )) {
      if (button.tooltip == 'Stop' || button.tooltip == 'Close') {
        expect(button.onPressed, isNull);
      }
    }

    gateway.complete(DoorCommand.open);
    await tester.pumpAndSettle();

    expect(find.text('开门指令已发送（0x1001）。'), findsOneWidget);
  });
}

Widget _buildPage(MockHardwareGateway gateway) {
  return ProviderScope(
    overrides: [
      deviceCommandHardwareGatewayProvider.overrideWithValue(gateway),
    ],
    child: const MaterialApp(home: DeviceCommandPage(deviceId: 'mock-device')),
  );
}

Future<void> _pumpDevicePage(
  WidgetTester tester,
  MockHardwareGateway gateway,
) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_buildPage(gateway));
}

class _RecordingHardwareGateway extends MockHardwareGateway {
  final List<DoorCommand> commands = <DoorCommand>[];
  int queryCount = 0;

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

  @override
  Future<RemoteControlListResult> queryRemotes({
    required String requestId,
    required String deviceId,
  }) async {
    queryCount += 1;
    return super.queryRemotes(requestId: requestId, deviceId: deviceId);
  }
}

class _PendingCommandGateway extends MockHardwareGateway {
  final Completer<CommandResult> _commandCompleter = Completer<CommandResult>();

  @override
  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  }) {
    return _commandCompleter.future;
  }

  void complete(DoorCommand command) {
    _commandCompleter.complete(
      CommandResult(
        requestId: 'pending-command',
        deviceId: 'mock-device',
        command: command,
        accepted: true,
      ),
    );
  }
}
