import '../entities/device_setting.dart';
import '../repositories/device_settings_repository.dart';

class SetDeviceSettingUseCase {
  const SetDeviceSettingUseCase(this._repository);

  final DeviceSettingsRepository _repository;

  Future<void> call({
    required String requestId,
    required String deviceId,
    required DeviceSettingKey key,
    required int rawValue,
  }) {
    final maximum = (1 << (key.byteWidth * 8)) - 1;
    if (rawValue < 0 || rawValue > maximum) {
      throw RangeError.range(rawValue, 0, maximum, key.name);
    }
    if (!key.supportsValue(rawValue)) {
      throw RangeError.value(
        rawValue,
        key.name,
        'Value is not supported by the device attribute protocol.',
      );
    }
    return _repository.setSetting(
      requestId: requestId,
      deviceId: deviceId,
      value: DeviceSettingValue(key: key, rawValue: rawValue),
    );
  }
}
