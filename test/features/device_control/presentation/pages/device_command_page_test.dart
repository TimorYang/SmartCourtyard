import 'dart:async';

import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/domain/entities/door_detail.dart';
import 'package:flinx/features/device_control/domain/repositories/door_detail_repository.dart';
import 'package:flinx/features/device_control/presentation/pages/device_command_page.dart';
import 'package:flinx/features/device_control/presentation/pages/device_settings_page.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders garage door controls and sends primary commands', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(tester, gateway);

    expect(find.text('Garage door'), findsOneWidget);
    expect(find.text('Operated cycles'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('4567'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('LED'), findsOneWidget);
    expect(find.text('Auto close'), findsOneWidget);
    expect(find.text('Partial open'), findsOneWidget);
    expect(find.text('More setting'), findsOneWidget);

    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.open);
    expect(gateway.deviceIds.last, 'SN-001');
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

  testWidgets('quick actions send light, partial open, and open settings', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(tester, gateway);

    await tester.tap(find.byKey(const ValueKey<String>('led-switch')));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.lightOn);
    expect(find.text('开灯指令已发送（0x1005）。'), findsOneWidget);

    final partialOpenAction = find.byKey(
      const ValueKey<String>('partial-open-action'),
    );
    await tester.ensureVisible(partialOpenAction);
    await tester.drag(find.byType(ListView).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(partialOpenAction);
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.partialOpen);
    expect(find.text('半开门指令已发送（0x1004）。'), findsOneWidget);

    final moreSettingsAction = find.byKey(
      const ValueKey<String>('more-settings-action'),
    );
    await tester.ensureVisible(moreSettingsAction);
    await tester.drag(find.byType(ListView).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(moreSettingsAction);
    await tester.pumpAndSettle();

    expect(gateway.queryCount, 0);
    expect(find.text('DEVICE SETTINGS'), findsOneWidget);
    expect(find.text('Transmitter management'), findsOneWidget);
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

  testWidgets('switches between records, command, and security tabs', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(tester, gateway);

    expect(find.text('Closed'), findsOneWidget);

    await tester.tap(find.byTooltip('Operation records'));
    await tester.pumpAndSettle();

    expect(find.text('OPERATION RECORD'), findsOneWidget);
    expect(find.text('Partial open setting'), findsOneWidget);
    expect(find.text('346054814@qq.com'), findsWidgets);

    await tester.tap(find.byTooltip('Security center'));
    await tester.pumpAndSettle();

    expect(find.text('Security center'), findsOneWidget);
    expect(find.text('Protecting...'), findsOneWidget);
    expect(find.text('General Evaluation'), findsOneWidget);
    expect(find.text('Safety Sensors Evaluation'), findsOneWidget);

    await tester.tap(find.byTooltip('Device command'));
    await tester.pumpAndSettle();

    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Garage door'), findsOneWidget);
  });

  testWidgets('renders on a compact screen without overflow', (tester) async {
    final gateway = _RecordingHardwareGateway();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildPage(gateway));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Security center'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Widget _buildPage(MockHardwareGateway gateway) {
  return ProviderScope(
    overrides: [
      deviceCommandHardwareGatewayProvider.overrideWithValue(gateway),
      doorDetailRepositoryProvider.overrideWithValue(
        const _FakeDoorDetailRepository(),
      ),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        initialLocation:
            '${DeviceCommandPage.routePath}?doorId=12&deviceId=mock-device',
        routes: [
          GoRoute(
            path: DeviceCommandPage.routePath,
            builder: (context, state) => DeviceCommandPage(
              doorId: state.uri.queryParameters['doorId'] ?? '',
              deviceId: state.uri.queryParameters['deviceId'] ?? '',
            ),
          ),
          GoRoute(
            path: DeviceSettingsPage.routePath,
            builder: (context, state) => DeviceSettingsPage(
              deviceId: state.uri.queryParameters['deviceId'] ?? '',
            ),
          ),
        ],
      ),
    ),
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
  await tester.pumpAndSettle();
}

class _RecordingHardwareGateway extends MockHardwareGateway {
  final List<DoorCommand> commands = <DoorCommand>[];
  final List<String> deviceIds = <String>[];
  int queryCount = 0;

  @override
  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  }) async {
    commands.add(command);
    deviceIds.add(deviceId);
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

class _FakeDoorDetailRepository implements DoorDetailRepository {
  const _FakeDoorDetailRepository();

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) async {
    return const DoorDetail(
      id: '12',
      name: 'Garage door',
      doorState: DoorState.closed,
      doorStateLabel: 'Closed',
      operatedCycles: 123,
      remainingCycles: 4567,
      hardwareSn: 'SN-001',
    );
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
