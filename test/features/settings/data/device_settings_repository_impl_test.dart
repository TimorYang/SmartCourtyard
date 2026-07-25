import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flinx/features/settings/data/repositories/device_settings_repository_impl.dart';
import 'package:flinx/features/settings/domain/entities/device_setting.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';

void main() {
  test('maps queried attributes to semantic settings', () async {
    final repository = DeviceSettingsRepositoryImpl(MockHardwareGateway());

    final values = await repository.querySettings(
      requestId: 'query-1',
      deviceId: 'device-1',
    );

    expect(values[DeviceSettingKey.partialOpen]?.rawValue, 7);
    expect(values[DeviceSettingKey.ledOffDelay]?.displayValue, '0x1E (30)');
    expect(values[DeviceSettingKey.autoCloseTime]?.displayValue, '0x0000 (0)');
  });

  test('encodes big-endian values and refreshes mock snapshot', () async {
    final gateway = MockHardwareGateway();
    final repository = DeviceSettingsRepositoryImpl(gateway);

    await repository.setSetting(
      requestId: 'set-1',
      deviceId: 'device-1',
      value: const DeviceSettingValue(
        key: DeviceSettingKey.autoCloseTime,
        rawValue: 0x0123,
      ),
    );
    final snapshot = await gateway.queryDeviceAttributes(
      requestId: 'query-2',
      deviceId: 'device-1',
    );
    final attribute = snapshot.attributes.singleWhere(
      (value) => value.id == DeviceSettingKey.autoCloseTime.attributeId,
    );

    expect(attribute.value, Uint8List.fromList(<int>[0x01, 0x23]));
  });
}
