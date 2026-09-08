import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flinx/features/settings/data/repositories/device_settings_repository_impl.dart';
import 'package:flinx/features/settings/domain/entities/device_setting.dart';
import 'package:flinx/features/settings/domain/entities/device_settings_snapshot.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';

void main() {
  test('preserves active report metadata in settings snapshots', () async {
    final gateway = MockHardwareGateway();
    final repository = DeviceSettingsRepositoryImpl(gateway);
    final snapshotFuture = repository.watchSettings(deviceId: 'device-1').first;

    gateway.emitDeviceAttributeSnapshot(
      DeviceAttributeSnapshot(
        deviceId: 'device-1',
        sequence: 42,
        timestampMillis: 1234,
        origin: DeviceAttributeReportOrigin.activeReport,
        attributes: [
          DeviceAttribute(id: 0x2712, value: Uint8List.fromList(<int>[0x21])),
        ],
      ),
    );

    final snapshot = await snapshotFuture;
    expect(snapshot.origin, DeviceSettingsSnapshotOrigin.activeReport);
    expect(snapshot.sequence, 42);
    expect(snapshot.timestampMillis, 1234);
    expect(snapshot.values[DeviceSettingKey.autoCloseTime]?.rawValue, 1);
  });

  test('emits disconnection only for the requested BLE device', () async {
    final gateway = MockHardwareGateway();
    final repository = DeviceSettingsRepositoryImpl(gateway);
    var disconnections = 0;
    final subscription = repository
        .watchDisconnections(deviceId: 'device-1')
        .listen((_) => disconnections++);
    addTearDown(subscription.cancel);

    gateway.emitBleConnectionEvent(
      const BleConnectionEvent(
        requestId: 'other-disconnect',
        deviceId: 'device-2',
        state: BleConnectionState.disconnected,
      ),
    );
    gateway.emitBleConnectionEvent(
      const BleConnectionEvent(
        requestId: 'target-connected',
        deviceId: 'device-1',
        state: BleConnectionState.connected,
      ),
    );
    gateway.emitBleConnectionEvent(
      const BleConnectionEvent(
        requestId: 'target-disconnect',
        deviceId: 'device-1',
        state: BleConnectionState.disconnected,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(disconnections, 1);
  });

  test('maps queried attributes to semantic settings', () async {
    final repository = DeviceSettingsRepositoryImpl(MockHardwareGateway());

    final values = await repository.querySettings(
      requestId: 'query-1',
      deviceId: 'device-1',
    );

    expect(values[DeviceSettingKey.partialOpen]?.rawValue, 7);
    expect(values[DeviceSettingKey.ledOffDelay]?.displayValue, '0x05 (5)');
    expect(values[DeviceSettingKey.autoCloseCondition]?.rawValue, 1);
    expect(values[DeviceSettingKey.autoCloseTime]?.displayValue, '0x00 (0)');
    expect(values[DeviceSettingKey.doorOpenReminder]?.rawValue, 10);
  });

  test(
    'encodes auto-close position and level as one-byte 0x2712 values',
    () async {
      final gateway = MockHardwareGateway();
      final repository = DeviceSettingsRepositoryImpl(gateway);

      for (final position in AutoClosePosition.values) {
        await repository.setSetting(
          requestId: 'set-auto-close-position-${position.name}',
          deviceId: 'device-1',
          value: DeviceSettingValue(
            key: DeviceSettingKey.autoCloseTime,
            rawValue: 9,
            wireValue: encodeAutoCloseProtocolValue(
              position: position,
              level: 9,
            ),
          ),
        );

        final snapshot = await gateway.queryDeviceAttributes(
          requestId: 'query-auto-close-position-${position.name}',
          deviceId: 'device-1',
        );
        final attribute = snapshot.attributes.singleWhere(
          (value) => value.id == 0x2712,
        );
        expect(
          attribute.value,
          Uint8List.fromList([position.wireValueBase | 0x09]),
        );
        expect(snapshot.attributes.any((value) => value.id == 0x2714), isTrue);
      }
    },
  );

  test('rejects direct auto-close condition writes', () async {
    final repository = DeviceSettingsRepositoryImpl(MockHardwareGateway());

    await expectLater(
      repository.setSetting(
        requestId: 'set-auto-close-condition',
        deviceId: 'device-1',
        value: const DeviceSettingValue(
          key: DeviceSettingKey.autoCloseCondition,
          rawValue: 2,
        ),
      ),
      throwsStateError,
    );
  });

  test(
    'encodes LED off delay levels using the original 0x2713 values',
    () async {
      final gateway = MockHardwareGateway();
      final repository = DeviceSettingsRepositoryImpl(gateway);

      await repository.setSetting(
        requestId: 'set-led-delay',
        deviceId: 'device-1',
        value: const DeviceSettingValue(
          key: DeviceSettingKey.ledOffDelay,
          rawValue: 5,
        ),
      );

      final snapshot = await gateway.queryDeviceAttributes(
        requestId: 'query-led-delay',
        deviceId: 'device-1',
      );
      expect(
        snapshot.attributes
            .singleWhere((attribute) => attribute.id == 0x2713)
            .value,
        Uint8List.fromList(<int>[0x05]),
      );
    },
  );

  test('encodes auto-close level as one byte at attribute 0x2712', () async {
    final gateway = MockHardwareGateway();
    final repository = DeviceSettingsRepositoryImpl(gateway);

    await repository.setSetting(
      requestId: 'set-1',
      deviceId: 'device-1',
      value: const DeviceSettingValue(
        key: DeviceSettingKey.autoCloseTime,
        rawValue: 9,
        wireValue: 0x19,
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
    expect(attribute.value, Uint8List.fromList(<int>[0x19]));
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
    expect(
      value?.sourceAttributeId,
      DeviceSettingKey.autoCloseTime.legacyAttributeId,
    );
  });

  test('reads 0x2712 time separately from the 0x2714 position', () async {
    final repository = DeviceSettingsRepositoryImpl(
      MockHardwareGateway(autoClosePosition: 0x02, autoCloseValue: 9),
    );

    final values = await repository.querySettings(
      requestId: 'query-combined',
      deviceId: 'device-1',
    );

    expect(values[DeviceSettingKey.autoCloseTime]?.rawValue, 9);
    expect(values[DeviceSettingKey.autoCloseTime]?.wireValue, isNull);
    expect(values[DeviceSettingKey.autoCloseTime]?.candidateValues, <int>[9]);
    expect(
      values[DeviceSettingKey.autoCloseCondition]?.rawValue,
      AutoClosePosition.anyPosition.protocolValue,
    );
    expect(
      values[DeviceSettingKey.autoCloseCondition]?.sourceAttributeId,
      0x2714,
    );
  });

  test(
    'maps legacy one-byte 0x2712 while retaining 0x2714 condition',
    () async {
      final repository = DeviceSettingsRepositoryImpl(
        MockHardwareGateway(autoCloseRawBytes: const <int>[0x03]),
      );

      final values = await repository.querySettings(
        requestId: 'query-legacy-2712',
        deviceId: 'device-1',
      );

      expect(values[DeviceSettingKey.autoCloseTime]?.rawValue, 3);
      expect(values[DeviceSettingKey.autoCloseTime]?.wireValue, isNull);
      expect(
        values[DeviceSettingKey.autoCloseCondition]?.rawValue,
        AutoClosePosition.upLimit.protocolValue,
      );
      expect(
        values[DeviceSettingKey.autoCloseCondition]?.sourceAttributeId,
        0x2714,
      );
    },
  );

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
      expect(
        value?.sourceAttributeId,
        DeviceSettingKey.autoCloseTime.attributeId,
      );
    },
  );

  test('always writes auto-close values to one-byte 0x2712', () async {
    final gateway = MockHardwareGateway(
      autoCloseAttributeId: 0x2725,
      autoCloseValue: 75,
    );
    final repository = DeviceSettingsRepositoryImpl(gateway);

    for (final rawValue in <int>[0, 1, 9]) {
      await repository.setSetting(
        requestId: 'set-2725-$rawValue',
        deviceId: 'device-1',
        value: DeviceSettingValue(
          key: DeviceSettingKey.autoCloseTime,
          rawValue: rawValue,
          wireValue: encodeAutoCloseProtocolValue(
            position: AutoClosePosition.anyPosition,
            level: rawValue,
          ),
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

      expect(attribute2712.value, Uint8List.fromList(<int>[0x20 | rawValue]));
      expect(attribute2725.value, Uint8List.fromList(<int>[0x00, 0x4B]));
      expect(
        snapshot.attributes.any((attribute) => attribute.id == 0x2714),
        isTrue,
      );
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
        isTrue,
      );
    },
  );

  test('maps every settings-dialog value to its protocol attribute', () async {
    final gateway = MockHardwareGateway();
    final repository = DeviceSettingsRepositoryImpl(gateway);
    const values = <DeviceSettingValue>[
      DeviceSettingValue(key: DeviceSettingKey.ledOffDelay, rawValue: 5),
      DeviceSettingValue(key: DeviceSettingKey.partialOpen, rawValue: 7),
      DeviceSettingValue(key: DeviceSettingKey.autoCloseCondition, rawValue: 1),
      DeviceSettingValue(
        key: DeviceSettingKey.autoCloseTime,
        rawValue: 9,
        wireValue: 0x19,
      ),
      DeviceSettingValue(key: DeviceSettingKey.openingSpeed, rawValue: 80),
      DeviceSettingValue(key: DeviceSettingKey.openingForce, rawValue: 5),
    ];

    for (final value in values.where(
      (value) => value.key != DeviceSettingKey.autoCloseCondition,
    )) {
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
      expect(attribute.unsignedValue, value.wireValue ?? value.rawValue);
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
