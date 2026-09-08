enum AutoClosePosition {
  upLimit(1, 0x10),
  anyPosition(2, 0x20);

  const AutoClosePosition(this.protocolValue, this.wireValueBase);

  /// Value reported independently by the read-only 0x2714 attribute.
  final int protocolValue;

  /// High-nibble base used by the one-byte 0x2712 value.
  final int wireValueBase;

  static AutoClosePosition? fromProtocolValue(int? value) {
    for (final position in values) {
      if (position.protocolValue == value) {
        return position;
      }
    }
    return null;
  }

  static AutoClosePosition? fromWireValue(int? value) {
    if (value == null) {
      return null;
    }
    for (final position in values) {
      if (value >= position.wireValueBase &&
          value <= position.wireValueBase + 0x09) {
        return position;
      }
    }
    return null;
  }
}

enum DeviceSettingKey {
  partialOpen(attributeId: 0x2711, byteWidth: 1),
  ledOffDelay(attributeId: 0x2713, byteWidth: 1),
  autoCloseCondition(attributeId: 0x2714, byteWidth: 1, writable: false),
  autoCloseTime(attributeId: 0x2712, byteWidth: 1, legacyAttributeId: 0x2725),
  openingForce(attributeId: 0x2726, byteWidth: 1),
  openingSpeed(attributeId: 0x2727, byteWidth: 1),
  doorOpenReminder(attributeId: 0x2728, byteWidth: 1, commandCode: 0x0E09);

  const DeviceSettingKey({
    this.attributeId,
    required this.byteWidth,
    int? protocolByteWidth,
    this.commandCode,
    this.legacyAttributeId,
    this.writable = true,
  }) : protocolByteWidth = protocolByteWidth ?? byteWidth;

  final int? attributeId;
  final int byteWidth;
  final int protocolByteWidth;
  final int? commandCode;
  final int? legacyAttributeId;
  final bool writable;

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
    DeviceSettingKey.autoCloseTime => throw UnsupportedError(
      'Auto-close requires a value from the device capability options.',
    ),
    DeviceSettingKey.doorOpenReminder => 10,
    _ => throw UnsupportedError('$name does not support enabled toggles.'),
  };

  /// Converts the app/capability value to the value carried by BLE.
  ///
  /// 0x2713 writes continue to use the original 0x01-0x09 values. The newer
  /// firmware representation is handled only when decoding a 0x0202 report.
  int toProtocolValue(int value) => value;

  /// Converts a 0x2713 value from a 0x0202 report to the capability level.
  ///
  /// Older firmware reports 0x01-0x09 directly. Newer firmware can report
  /// the same level in tens (0x0A, 0x14, ...), so values above 0x09 are
  /// normalized by dividing by ten before matching capability options.
  int fromProtocolValue(int value) {
    return this == DeviceSettingKey.ledOffDelay && value > 0x09
        ? value ~/ 0x0A
        : value;
  }

  /// Range defined by the door BLE protocol's attribute table.
  ///
  /// The byte width is still used for serialization; this range prevents
  /// values that fit on the wire but are invalid for the motor firmware.
  bool supportsValue(int value) {
    return switch (this) {
      DeviceSettingKey.partialOpen => value >= 0 && value <= 0x12,
      DeviceSettingKey.ledOffDelay => value >= 1 && value <= 9,
      DeviceSettingKey.autoCloseCondition =>
        value == AutoClosePosition.upLimit.protocolValue ||
            value == AutoClosePosition.anyPosition.protocolValue,
      DeviceSettingKey.autoCloseTime => value >= 0 && value <= 9,
      DeviceSettingKey.openingForce => value >= 1 && value <= 9,
      DeviceSettingKey.openingSpeed => value >= 60 && value <= 100,
      DeviceSettingKey.doorOpenReminder =>
        value == 0 || value == 5 || value == 10 || value == 15,
    };
  }
}

class DeviceSettingValue {
  const DeviceSettingValue({
    required this.key,
    required this.rawValue,
    this.candidateValues = const <int>[],
    this.sourceAttributeId,
    this.wireValue,
  });

  final DeviceSettingKey key;
  final int rawValue;
  final List<int> candidateValues;
  final int? sourceAttributeId;

  /// Complete protocol value when the semantic value is encoded as a
  /// composite value, such as auto-close position plus level in 0x2712.
  final int? wireValue;

  String get hexValue =>
      '0x${rawValue.toRadixString(16).padLeft(key.byteWidth * 2, '0').toUpperCase()}';

  String get displayValue => '$hexValue ($rawValue)';
}

int encodeAutoCloseProtocolValue({
  required AutoClosePosition position,
  required int level,
}) {
  if (level < 0 || level > 9) {
    throw RangeError.range(level, 0, 9, 'level');
  }
  return position.wireValueBase | level;
}
