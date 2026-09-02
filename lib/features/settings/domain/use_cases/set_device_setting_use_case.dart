import '../entities/device_setting.dart';
import '../repositories/device_settings_repository.dart';

class SetDeviceSettingUseCase {
  const SetDeviceSettingUseCase(this._repository);

  final DeviceSettingsRepository _repository;

  Future<void> call({
    required String requestId,
    required String deviceId,
    required DeviceSettingValue value,
  }) {
    final maximum = (1 << (value.key.byteWidth * 8)) - 1;
    if (value.rawValue < 0 || value.rawValue > maximum) {
      throw RangeError.range(value.rawValue, 0, maximum, value.key.name);
    }
    if (!value.key.supportsValue(value.rawValue)) {
      throw RangeError.value(
        value.rawValue,
        value.key.name,
        'Value is not supported by the device attribute protocol.',
      );
    }
    return _repository.setSetting(
      requestId: requestId,
      deviceId: deviceId,
      value: value,
    );
  }
}
