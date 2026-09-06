import '../entities/device_setting.dart';
import '../entities/device_settings_snapshot.dart';

abstract interface class DeviceSettingsRepository {
  Stream<DeviceSettingsSnapshot> watchSettings({required String deviceId});

  Stream<void> watchDisconnections({required String deviceId});

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
