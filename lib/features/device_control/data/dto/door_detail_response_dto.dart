class DoorDetailResponseDto {
  const DoorDetailResponseDto({
    required this.id,
    required this.name,
    this.doorType,
    this.doorTypeLabel,
    this.controlMode,
    this.controlModeLabel,
    this.onlineStatus,
    this.onlineStatusLabel,
    this.doorState,
    this.doorStateLabel,
    this.positionPercent,
    this.coverFileId,
    this.operatorAvatarFileId,
    this.operatedCycles,
    this.remainingCycles,
    this.ledStatus,
    this.ledStatusLabel,
    this.autoCloseEnabled,
    this.openReminderEnabled,
    this.partialOpenValue,
  });

  final String id;
  final String name;
  final int? doorType;
  final String? doorTypeLabel;
  final int? controlMode;
  final String? controlModeLabel;
  final int? onlineStatus;
  final String? onlineStatusLabel;
  final int? doorState;
  final String? doorStateLabel;
  final double? positionPercent;
  final int? coverFileId;
  final int? operatorAvatarFileId;
  final int? operatedCycles;
  final int? remainingCycles;
  final int? ledStatus;
  final String? ledStatusLabel;
  final bool? autoCloseEnabled;
  final bool? openReminderEnabled;
  final int? partialOpenValue;

  factory DoorDetailResponseDto.fromJson(Map<String, dynamic> json) {
    return DoorDetailResponseDto(
      id: _parseString(json['id']),
      name: json['name'] as String? ?? '',
      doorType: _parseNullableInt(json['doorType']),
      doorTypeLabel: json['doorTypeLabel'] as String?,
      controlMode: _parseNullableInt(json['controlMode']),
      controlModeLabel: json['controlModeLabel'] as String?,
      onlineStatus: _parseNullableInt(json['onlineStatus']),
      onlineStatusLabel: json['onlineStatusLabel'] as String?,
      doorState: _parseNullableInt(json['doorState']),
      doorStateLabel: json['doorStateLabel'] as String?,
      positionPercent: _parseNullableDouble(json['positionPercent']),
      coverFileId: _parseNullableInt(json['coverFileId']),
      operatorAvatarFileId: _parseNullableInt(json['operatorAvatarFileId']),
      operatedCycles: _parseNullableInt(json['operatedCycles']),
      remainingCycles: _parseNullableInt(json['remainingCycles']),
      ledStatus: _parseNullableInt(json['ledStatus']),
      ledStatusLabel: json['ledStatusLabel'] as String?,
      autoCloseEnabled: json['autoCloseEnabled'] as bool?,
      openReminderEnabled: json['openReminderEnabled'] as bool?,
      partialOpenValue: _parseNullableInt(json['partialOpenValue']),
    );
  }

  static String _parseString(Object? value) {
    return value?.toString() ?? '';
  }

  static int? _parseNullableInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static double? _parseNullableDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
