import '../entities/device_setting.dart';
import '../repositories/device_settings_repository.dart';

class QueryDeviceSettingsUseCase {
  const QueryDeviceSettingsUseCase(this._repository);

  final DeviceSettingsRepository _repository;

  Future<Map<DeviceSettingKey, DeviceSettingValue>> call({
    required String requestId,
    required String deviceId,
  }) {
    return _repository.querySettings(requestId: requestId, deviceId: deviceId);
  }
}
