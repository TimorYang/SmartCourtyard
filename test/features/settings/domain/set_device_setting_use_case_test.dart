import 'package:flutter_test/flutter_test.dart';
import 'package:flinx/features/settings/domain/entities/device_setting.dart';
import 'package:flinx/features/settings/domain/repositories/device_settings_repository.dart';
import 'package:flinx/features/settings/domain/use_cases/set_device_setting_use_case.dart';

void main() {
  test(
    'encodes 0x2712 positions in the high nibble and levels in the low nibble',
    () {
      expect(
        encodeAutoCloseProtocolValue(
          position: AutoClosePosition.upLimit,
          level: 0,
        ),
        0x10,
      );
      expect(
        encodeAutoCloseProtocolValue(
          position: AutoClosePosition.upLimit,
          level: 9,
        ),
        0x19,
      );
      expect(
        encodeAutoCloseProtocolValue(
          position: AutoClosePosition.anyPosition,
          level: 0,
        ),
        0x20,
      );
      expect(
        encodeAutoCloseProtocolValue(
          position: AutoClosePosition.anyPosition,
          level: 9,
        ),
        0x29,
      );
      expect(AutoClosePosition.fromWireValue(0x10), AutoClosePosition.upLimit);
      expect(AutoClosePosition.fromWireValue(0x19), AutoClosePosition.upLimit);
      expect(
        AutoClosePosition.fromWireValue(0x20),
        AutoClosePosition.anyPosition,
      );
      expect(
        AutoClosePosition.fromWireValue(0x29),
        AutoClosePosition.anyPosition,
      );
      expect(AutoClosePosition.fromWireValue(0x1A), isNull);
      expect(AutoClosePosition.fromWireValue(0x2A), isNull);
    },
  );

  test('rejects values that do not fit the protocol width', () async {
    final useCase = SetDeviceSettingUseCase(_Repository());

    expect(
      () => useCase(
        requestId: 'request',
        deviceId: 'device',
        value: const DeviceSettingValue(
          key: DeviceSettingKey.openingForce,
          rawValue: 256,
        ),
      ),
      throwsRangeError,
    );
    expect(
      () => useCase(
        requestId: 'request-led-delay-invalid',
        deviceId: 'device',
        value: const DeviceSettingValue(
          key: DeviceSettingKey.ledOffDelay,
          rawValue: 0x0B,
        ),
      ),
      throwsRangeError,
    );
  });

  test('rejects values outside the BLE attribute definitions', () async {
    final useCase = SetDeviceSettingUseCase(_Repository());

    expect(
      () => useCase(
        requestId: 'request',
        deviceId: 'device',
        value: const DeviceSettingValue(
          key: DeviceSettingKey.openingSpeed,
          rawValue: 59,
        ),
      ),
      throwsRangeError,
    );
    expect(
      () => useCase(
        requestId: 'request',
        deviceId: 'device',
        value: const DeviceSettingValue(
          key: DeviceSettingKey.doorOpenReminder,
          rawValue: 6,
        ),
      ),
      throwsRangeError,
    );
    expect(
      () => useCase(
        requestId: 'request',
        deviceId: 'device',
        value: const DeviceSettingValue(
          key: DeviceSettingKey.autoCloseTime,
          rawValue: -1,
        ),
      ),
      throwsRangeError,
    );
    expect(
      () => useCase(
        requestId: 'request',
        deviceId: 'device',
        value: const DeviceSettingValue(
          key: DeviceSettingKey.autoCloseTime,
          rawValue: 256,
        ),
      ),
      throwsRangeError,
    );
  });

  test(
    'accepts level values with a complete one-byte auto-close wire value',
    () async {
      final useCase = SetDeviceSettingUseCase(_Repository());

      for (final rawValue in <int>[0, 1, 9]) {
        await expectLater(
          useCase(
            requestId: 'request-$rawValue',
            deviceId: 'device',
            value: DeviceSettingValue(
              key: DeviceSettingKey.autoCloseTime,
              rawValue: rawValue,
              wireValue: encodeAutoCloseProtocolValue(
                position: AutoClosePosition.upLimit,
                level: rawValue,
              ),
            ),
          ),
          completes,
        );
      }
    },
  );

  test('rejects auto-close levels outside 0-9', () {
    final useCase = SetDeviceSettingUseCase(_Repository());

    expect(
      () => useCase(
        requestId: 'request-2712-invalid',
        deviceId: 'device',
        value: DeviceSettingValue(
          key: DeviceSettingKey.autoCloseTime,
          rawValue: 10,
          wireValue: encodeAutoCloseProtocolValue(
            position: AutoClosePosition.upLimit,
            level: 9,
          ),
        ),
      ),
      throwsRangeError,
    );
  });

  test('rejects an auto-close wire value that disagrees with its level', () {
    final useCase = SetDeviceSettingUseCase(_Repository());

    expect(
      () => useCase(
        requestId: 'request-2712-mismatch',
        deviceId: 'device',
        value: const DeviceSettingValue(
          key: DeviceSettingKey.autoCloseTime,
          rawValue: 1,
          wireValue: 0x12,
        ),
      ),
      throwsStateError,
    );
  });

  test('requires a complete auto-close wire value', () {
    final useCase = SetDeviceSettingUseCase(_Repository());

    expect(
      () => useCase(
        requestId: 'request-auto-close-without-route',
        deviceId: 'device',
        value: const DeviceSettingValue(
          key: DeviceSettingKey.autoCloseTime,
          rawValue: 1,
        ),
      ),
      throwsStateError,
    );
  });

  test('does not allow direct writes to the auto-close condition point', () {
    final useCase = SetDeviceSettingUseCase(_Repository());

    expect(
      () => useCase(
        requestId: 'request-auto-close-condition',
        deviceId: 'device',
        value: const DeviceSettingValue(
          key: DeviceSettingKey.autoCloseCondition,
          rawValue: 1,
        ),
      ),
      throwsStateError,
    );
  });
}

class _Repository implements DeviceSettingsRepository {
  @override
  Future<Map<DeviceSettingKey, DeviceSettingValue>> querySettings({
    required String requestId,
    required String deviceId,
  }) async => const <DeviceSettingKey, DeviceSettingValue>{};

  @override
  Future<void> setSetting({
    required String requestId,
    required String deviceId,
    required DeviceSettingValue value,
  }) async {}

  @override
  Stream<Map<DeviceSettingKey, DeviceSettingValue>> watchSettings({
    required String deviceId,
  }) => const Stream<Map<DeviceSettingKey, DeviceSettingValue>>.empty();
}
