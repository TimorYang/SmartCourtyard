import 'package:flinx/features/security_center/application/safety_sensor_management_controller.dart';
import 'package:flinx/features/security_center/application/safety_sensor_management_providers.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads, exposes pending deletion, and refreshes the list', () async {
    final gateway = MockHardwareGateway()
      ..connectedBleDevices['device-1'] = const ConnectedBleDevice(
        deviceId: 'device-1',
        state: BleConnectionState.connected,
      )
      ..safetyAccessoryDeleteDelay = const Duration(milliseconds: 20);
    final container = ProviderContainer(
      overrides: [
        safetySensorManagementHardwareGatewayProvider.overrideWithValue(
          gateway,
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = safetySensorManagementControllerProvider('device-1');
    final controller = container.read(provider.notifier);

    await controller.load();
    expect(container.read(provider).sensors, hasLength(2));

    final sensor = container.read(provider).sensors.first;
    final deletion = controller.deleteSensor(sensor);
    expect(container.read(provider).deletingSerialNumber, sensor.serialNumber);
    expect(await controller.deleteSensor(sensor), isFalse);
    expect(await deletion, isTrue);
    expect(container.read(provider).deletingSerialNumber, isNull);
    expect(container.read(provider).sensors, hasLength(1));
  });

  test('keeps the sensor when deletion fails', () async {
    final gateway = MockHardwareGateway()
      ..connectedBleDevices['device-1'] = const ConnectedBleDevice(
        deviceId: 'device-1',
        state: BleConnectionState.connected,
      )
      ..safetyAccessoryDeleteSucceeds = false;
    final container = ProviderContainer(
      overrides: [
        safetySensorManagementHardwareGatewayProvider.overrideWithValue(
          gateway,
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = safetySensorManagementControllerProvider('device-1');
    final controller = container.read(provider.notifier);

    await controller.load();
    final sensor = container.read(provider).sensors.first;
    expect(await controller.deleteSensor(sensor), isFalse);
    expect(container.read(provider).sensors, hasLength(2));
    expect(container.read(provider).error, isNotNull);
  });
}
