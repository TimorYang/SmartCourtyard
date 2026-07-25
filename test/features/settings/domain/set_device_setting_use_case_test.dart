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
        key: DeviceSettingKey.openingForce,
        rawValue: 256,
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
        key: DeviceSettingKey.openingSpeed,
        rawValue: 59,
      ),
      throwsRangeError,
    );
    expect(
      () => useCase(
        requestId: 'request',
        deviceId: 'device',
        key: DeviceSettingKey.doorOpenReminder,
        rawValue: 6,
      ),
      throwsRangeError,
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
