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
    if (!value.key.writable) {
      throw StateError('Setting ${value.key.name} is read-only.');
    }
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
    if (value.key == DeviceSettingKey.autoCloseTime &&
        value.wireValue == null) {
      throw StateError(
        'Auto-close writes require a complete 0x2712 wire value.',
      );
    }
    final wireValue = value.wireValue;
    if (wireValue != null) {
      final wireMaximum = (1 << (value.key.protocolByteWidth * 8)) - 1;
      if (wireValue < 0 || wireValue > wireMaximum) {
        throw RangeError.range(
          wireValue,
          0,
          wireMaximum,
          '${value.key.name}.wireValue',
        );
      }
      if (value.key == DeviceSettingKey.autoCloseTime) {
        final wirePosition = AutoClosePosition.fromWireValue(wireValue);
        final wireLevel = wireValue & 0x0F;
        if (wirePosition == null || wireLevel != value.rawValue) {
          throw StateError(
            'Auto-close wire value must encode the selected position and level.',
          );
        }
      }
    }
    return _repository.setSetting(
      requestId: requestId,
      deviceId: deviceId,
      value: value,
    );
  }
}
