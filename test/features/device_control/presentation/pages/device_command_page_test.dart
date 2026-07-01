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
    expect(find.text('开始对码'), findsOneWidget);
    expect(find.text('取消对码'), findsOneWidget);
    expect(find.text('查询遥控器'), findsOneWidget);
    expect(find.text('全部删除'), findsOneWidget);

    await tester.tap(find.text('开门'));
    await tester.pumpAndSettle();

    expect(find.text('开门指令已发送（0x1001）。'), findsOneWidget);

    await tester.tap(find.text('开始对码'));
    await tester.pumpAndSettle();

    expect(find.text('开始对码成功，故障码 0x00000000。'), findsOneWidget);
  });

  testWidgets('queries, renames, deletes, and clears remote controls', (
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

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查询遥控器'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('遥控器1'), findsOneWidget);
    expect(find.text('0x00000003'), findsOneWidget);
    expect(find.text('遥控器2'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('改名').first);
    await tester.tap(find.byTooltip('改名').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '客厅');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('客厅'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('删除').first);
    await tester.tap(find.byTooltip('删除').first);
    await tester.pumpAndSettle();

    expect(find.text('客厅'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部删除'));
    await tester.pumpAndSettle();

    expect(find.text('遥控器2'), findsNothing);
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

  testWidgets('shows pending state while remote pairing is in progress', (
    tester,
  ) async {
    final gateway = _PendingRemotePairingGateway();

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

    await tester.tap(find.text('开始对码'));
    await tester.pump();

    expect(find.text('对码中...'), findsOneWidget);
    expect(
      tester
          .widgetList<AbsorbPointer>(find.byType(AbsorbPointer))
          .any((widget) => widget.absorbing),
      isTrue,
    );

    gateway.complete();
    await tester.pumpAndSettle();

    expect(find.text('开始对码成功，故障码 0x00000000。'), findsOneWidget);
  });
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

class _PendingRemotePairingGateway extends MockHardwareGateway {
  final Completer<RemotePairingResult> _pairingCompleter =
      Completer<RemotePairingResult>();

  @override
  Future<RemotePairingResult> pairRemote({
    required String requestId,
    required String deviceId,
    required RemotePairingAction action,
  }) {
    return _pairingCompleter.future;
  }

  void complete() {
    _pairingCompleter.complete(
      const RemotePairingResult(
        requestId: 'pending-pairing',
        deviceId: 'mock-ble-device',
        action: RemotePairingAction.start,
        status: RemotePairingStatus.success,
        reasonCode: 0x00000000,
      ),
    );
  }
}
