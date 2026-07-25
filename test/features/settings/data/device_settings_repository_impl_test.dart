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
    expect(values[DeviceSettingKey.ledOffDelay]?.displayValue, '0x05 (5)');
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

  test('maps every settings-dialog value to its protocol attribute', () async {
    final gateway = MockHardwareGateway();
    final repository = DeviceSettingsRepositoryImpl(gateway);
    const values = <DeviceSettingValue>[
      DeviceSettingValue(key: DeviceSettingKey.ledOffDelay, rawValue: 5),
      DeviceSettingValue(key: DeviceSettingKey.partialOpen, rawValue: 7),
      DeviceSettingValue(key: DeviceSettingKey.autoCloseTime, rawValue: 60),
      DeviceSettingValue(key: DeviceSettingKey.openingSpeed, rawValue: 80),
      DeviceSettingValue(key: DeviceSettingKey.doorOpenReminder, rawValue: 10),
      DeviceSettingValue(key: DeviceSettingKey.openingForce, rawValue: 5),
    ];

    for (final value in values) {
      await repository.setSetting(
        requestId: 'set-${value.key.name}',
        deviceId: 'device-1',
        value: value,
      );
    }

    final snapshot = await gateway.queryDeviceAttributes(
      requestId: 'query-all',
      deviceId: 'device-1',
    );
    for (final value in values) {
      final attribute = snapshot.attributes.singleWhere(
        (attribute) => attribute.id == value.key.attributeId,
      );
      expect(attribute.unsignedValue, value.rawValue);
    }
  });
}
