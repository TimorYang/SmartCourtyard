import '../entities/device_setting.dart';

abstract interface class DeviceSettingsRepository {
  Stream<Map<DeviceSettingKey, DeviceSettingValue>> watchSettings({
    required String deviceId,
  });

  Future<Map<DeviceSettingKey, DeviceSettingValue>> querySettings({
    required String requestId,
    required String deviceId,
  });

  Future<void> setSetting({
    required String requestId,
    required String deviceId,
    required DeviceSettingValue value,
  });
}
