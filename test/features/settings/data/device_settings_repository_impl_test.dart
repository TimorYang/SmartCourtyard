import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flinx/features/settings/data/repositories/device_settings_repository_impl.dart';
import 'package:flinx/features/settings/domain/entities/device_setting.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';

void main() {
  test('maps queried attributes to semantic settings', () async {
    final repository = DeviceSettingsRepositoryImpl(MockHardwareGateway());

    final values = await repository.querySettings(
      requestId: 'query-1',
      deviceId: 'device-1',
    );

    expect(values[DeviceSettingKey.partialOpen]?.rawValue, 7);
    expect(values[DeviceSettingKey.ledOffDelay]?.displayValue, '0x05 (5)');
    expect(values[DeviceSettingKey.autoCloseTime]?.displayValue, '0x00 (0)');
  });

  test('encodes auto-close time as one byte at attribute 0x2712', () async {
    final gateway = MockHardwareGateway();
    final repository = DeviceSettingsRepositoryImpl(gateway);

    await repository.setSetting(
      requestId: 'set-1',
      deviceId: 'device-1',
      value: const DeviceSettingValue(
        key: DeviceSettingKey.autoCloseTime,
        rawValue: 9,
      ),
    );
    final snapshot = await gateway.queryDeviceAttributes(
      requestId: 'query-2',
      deviceId: 'device-1',
    );
    final attribute = snapshot.attributes.singleWhere(
      (value) => value.id == DeviceSettingKey.autoCloseTime.attributeId,
    );

    expect(attribute.id, 0x2712);
    expect(attribute.value, Uint8List.fromList(<int>[0x09]));
  });

  test('maps 0x2725 to auto-close time with its two-byte protocol', () async {
    final repository = DeviceSettingsRepositoryImpl(
      MockHardwareGateway(autoCloseAttributeId: 0x2725, autoCloseValue: 75),
    );

    final values = await repository.querySettings(
      requestId: 'query-2725',
      deviceId: 'device-1',
    );

    final value = values[DeviceSettingKey.autoCloseTime];
    expect(value?.rawValue, 75);
    expect(value?.candidateValues, <int>[75]);
  });

  test(
    'keeps both reported auto-close values and matches 0x2712 first',
    () async {
      final repository = DeviceSettingsRepositoryImpl(
        _BothAutoCloseMockHardwareGateway(),
      );

      final values = await repository.querySettings(
        requestId: 'query-both',
        deviceId: 'device-1',
      );

      final value = values[DeviceSettingKey.autoCloseTime];
      expect(value?.rawValue, 3);
      expect(value?.candidateValues, <int>[3, 75]);
    },
  );

  test('always writes auto-close values to one-byte 0x2712', () async {
    final gateway = MockHardwareGateway(
      autoCloseAttributeId: 0x2725,
      autoCloseValue: 75,
    );
    final repository = DeviceSettingsRepositoryImpl(gateway);

    for (final rawValue in <int>[0, 1, 15, 90, 255]) {
      await repository.setSetting(
        requestId: 'set-2725-$rawValue',
        deviceId: 'device-1',
        value: DeviceSettingValue(
          key: DeviceSettingKey.autoCloseTime,
          rawValue: rawValue,
        ),
      );

      final snapshot = await gateway.queryDeviceAttributes(
        requestId: 'query-2725-after-$rawValue',
        deviceId: 'device-1',
      );
      final attribute2712 = snapshot.attributes.singleWhere(
        (value) => value.id == 0x2712,
      );
      final attribute2725 = snapshot.attributes.singleWhere(
        (value) => value.id == 0x2725,
      );

      expect(attribute2712.value, Uint8List.fromList(<int>[rawValue]));
      expect(attribute2725.value, Uint8List.fromList(<int>[0x00, 0x4B]));
    }
  });

  test(
    'sends door reminder through cmd 0x0E09 instead of an attribute write',
    () async {
      final gateway = MockHardwareGateway();
      final repository = DeviceSettingsRepositoryImpl(gateway);

      for (final rawValue in <int>[0, 5, 10, 15]) {
        await repository.setSetting(
          requestId: 'set-reminder-$rawValue',
          deviceId: 'device-1',
          value: DeviceSettingValue(
            key: DeviceSettingKey.doorOpenReminder,
            rawValue: rawValue,
          ),
        );
      }

      expect(gateway.doorOpenReminderValues, <int>[0, 5, 10, 15]);
      final snapshot = await gateway.queryDeviceAttributes(
        requestId: 'query-reminder',
        deviceId: 'device-1',
      );
      expect(
        snapshot.attributes.any((attribute) => attribute.id == 0x2728),
        isFalse,
      );
    },
  );

  test('maps every settings-dialog value to its protocol attribute', () async {
    final gateway = MockHardwareGateway();
    final repository = DeviceSettingsRepositoryImpl(gateway);
    const values = <DeviceSettingValue>[
      DeviceSettingValue(key: DeviceSettingKey.ledOffDelay, rawValue: 5),
      DeviceSettingValue(key: DeviceSettingKey.partialOpen, rawValue: 7),
      DeviceSettingValue(key: DeviceSettingKey.autoCloseTime, rawValue: 9),
      DeviceSettingValue(key: DeviceSettingKey.openingSpeed, rawValue: 80),
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

class _BothAutoCloseMockHardwareGateway extends MockHardwareGateway {
  _BothAutoCloseMockHardwareGateway()
    : super(autoCloseAttributeId: 0x2725, autoCloseValue: 75);

  @override
  Future<DeviceAttributeSnapshot> queryDeviceAttributes({
    required String requestId,
    required String deviceId,
  }) async {
    final snapshot = await super.queryDeviceAttributes(
      requestId: requestId,
      deviceId: deviceId,
    );
    return DeviceAttributeSnapshot(
      requestId: snapshot.requestId,
      deviceId: snapshot.deviceId,
      sequence: snapshot.sequence,
      timestampMillis: snapshot.timestampMillis,
      origin: snapshot.origin,
      attributes: <DeviceAttribute>[
        for (final attribute in snapshot.attributes) attribute,
        DeviceAttribute(id: 0x2712, value: Uint8List.fromList(<int>[0x03])),
      ],
    );
  }
}
