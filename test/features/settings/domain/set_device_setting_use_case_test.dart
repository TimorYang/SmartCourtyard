import 'package:flutter_test/flutter_test.dart';
import 'package:flinx/features/settings/domain/entities/device_setting.dart';
import 'package:flinx/features/settings/domain/repositories/device_settings_repository.dart';
import 'package:flinx/features/settings/domain/use_cases/set_device_setting_use_case.dart';

void main() {
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

  test('accepts one-byte auto-close option values for 0x2712', () async {
    final useCase = SetDeviceSettingUseCase(_Repository());

    for (final rawValue in <int>[0, 15, 90, 255]) {
      await expectLater(
        useCase(
          requestId: 'request-$rawValue',
          deviceId: 'device',
          value: DeviceSettingValue(
            key: DeviceSettingKey.autoCloseTime,
            rawValue: rawValue,
          ),
        ),
        completes,
      );
    }
  });

  test('rejects auto-close values that do not fit one-byte 0x2712', () {
    final useCase = SetDeviceSettingUseCase(_Repository());

    expect(
      () => useCase(
        requestId: 'request-2712-invalid',
        deviceId: 'device',
        value: const DeviceSettingValue(
          key: DeviceSettingKey.autoCloseTime,
          rawValue: 256,
        ),
      ),
      throwsRangeError,
    );
  });

  test('does not require a reported BLE route for auto-close writes', () async {
    final useCase = SetDeviceSettingUseCase(_Repository());

    await expectLater(
      useCase(
        requestId: 'request-auto-close-without-route',
        deviceId: 'device',
        value: const DeviceSettingValue(
          key: DeviceSettingKey.autoCloseTime,
          rawValue: 1,
        ),
      ),
      completes,
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
