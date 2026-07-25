enum DeviceSettingKey {
  partialOpen(0x2711, 1),
  ledOffDelay(0x2713, 1),
  autoCloseCondition(0x2714, 1),
  autoCloseTime(0x2725, 2),
  openingForce(0x2726, 1),
  openingSpeed(0x2727, 1),
  doorOpenReminder(0x2728, 1);

  const DeviceSettingKey(this.attributeId, this.byteWidth);

  final int attributeId;
  final int byteWidth;
}

class DeviceSettingValue {
  const DeviceSettingValue({required this.key, required this.rawValue});

  final DeviceSettingKey key;
  final int rawValue;

  String get hexValue =>
      '0x${rawValue.toRadixString(16).padLeft(key.byteWidth * 2, '0').toUpperCase()}';

  String get displayValue => '$hexValue ($rawValue)';
}
