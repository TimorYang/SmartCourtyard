import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/presentation/pages/device_command_page.dart';
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

    expect(find.text('开门指令已接收。'), findsOneWidget);
  });
}
