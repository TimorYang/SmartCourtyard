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

  String get capabilityCode => switch (this) {
    DeviceSettingKey.partialOpen => 'PARTIAL_OPEN',
    DeviceSettingKey.ledOffDelay => 'LED_OFF_DELAY',
    DeviceSettingKey.autoCloseCondition => 'AUTO_CLOSE_CONDITION',
    DeviceSettingKey.autoCloseTime => 'AUTO_CLOSE',
    DeviceSettingKey.openingForce => 'FORCE_MARGIN',
    DeviceSettingKey.openingSpeed => 'OPENING_SPEED',
    DeviceSettingKey.doorOpenReminder => 'DOOR_OPEN_REMINDER',
  };

  bool get supportsEnabledToggle =>
      this == DeviceSettingKey.autoCloseTime ||
      this == DeviceSettingKey.doorOpenReminder;

  int get defaultEnabledValue => switch (this) {
    DeviceSettingKey.autoCloseTime => 30,
    DeviceSettingKey.doorOpenReminder => 10,
    _ => throw UnsupportedError('$name does not support enabled toggles.'),
  };

  /// Range defined by the door BLE protocol's attribute table.
  ///
  /// The byte width is still used for serialization; this range prevents
  /// values that fit on the wire but are invalid for the motor firmware.
  bool supportsValue(int value) {
    return switch (this) {
      DeviceSettingKey.partialOpen => value >= 0 && value <= 0x12,
      DeviceSettingKey.ledOffDelay => value >= 1 && value <= 9,
      DeviceSettingKey.autoCloseCondition => value >= 0 && value <= 0xFF,
      DeviceSettingKey.autoCloseTime => value >= 0 && value <= 990,
      DeviceSettingKey.openingForce => value >= 1 && value <= 9,
      DeviceSettingKey.openingSpeed => value >= 60 && value <= 100,
      DeviceSettingKey.doorOpenReminder =>
        value == 0 || value == 5 || value == 10 || value == 15,
    };
  }
}

class DeviceSettingValue {
  const DeviceSettingValue({required this.key, required this.rawValue});

  final DeviceSettingKey key;
  final int rawValue;

  String get hexValue =>
      '0x${rawValue.toRadixString(16).padLeft(key.byteWidth * 2, '0').toUpperCase()}';

  String get displayValue => '$hexValue ($rawValue)';
}
