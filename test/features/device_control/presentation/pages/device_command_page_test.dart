import 'dart:async';

import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/presentation/pages/device_command_page.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows command buttons and sends supported door command', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceCommandHardwareGatewayProvider.overrideWithValue(
            MockHardwareGateway(),
          ),
        ],
        child: const MaterialApp(
          home: DeviceCommandPage(deviceId: 'mock-ble-device'),
        ),
      ),
    );

    for (final action in DeviceCommandAction.values) {
      expect(find.text(action.label), findsOneWidget);
    }

    await tester.tap(find.text('开门'));
    await tester.pumpAndSettle();

    expect(find.text('开门指令已发送（0x1001）。'), findsOneWidget);
  });

  testWidgets(
    'keeps command buttons visually enabled while command is pending',
    (tester) async {
      final gateway = _PendingCommandGateway();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceCommandHardwareGatewayProvider.overrideWithValue(gateway),
          ],
          child: const MaterialApp(
            home: DeviceCommandPage(deviceId: 'mock-ble-device'),
          ),
        ),
      );

      await tester.tap(find.text('开灯'));
      await tester.pump();

      expect(find.text('发送中...'), findsOneWidget);
      expect(
        tester
            .widgetList<AbsorbPointer>(find.byType(AbsorbPointer))
            .any((widget) => widget.absorbing),
        isTrue,
      );

      for (final button in tester.widgetList<FilledButton>(
        find.byType(FilledButton),
      )) {
        expect(button.onPressed, isNotNull);
      }

      gateway.complete();
      await tester.pumpAndSettle();

      expect(find.text('开灯指令已发送（0x1005）。'), findsOneWidget);
    },
  );
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

  void complete() {
    _commandCompleter.complete(
      const CommandResult(
        requestId: 'pending-command',
        deviceId: 'mock-ble-device',
        command: DoorCommand.lightOn,
        accepted: true,
      ),
    );
  }
}
