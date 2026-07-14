class DoorDetailResponseDto {
  const DoorDetailResponseDto({
    required this.id,
    required this.name,
    this.sceneId,
    this.doorType,
    this.doorTypeLabel,
    this.controlSource,
    this.controlSourceLabel,
    this.controlMode,
    this.controlModeLabel,
    this.onlineStatus,
    this.onlineStatusLabel,
    this.doorState,
    this.doorStateLabel,
    this.positionPercent,
    this.coverMode,
    this.coverModeLabel,
    this.coverFileId,
    this.top = false,
    this.sceneName,
    this.operatedCycles,
    this.remainingCycles,
    this.hardwareSn,
    this.model,
    this.firmwareVersion,
    this.hardwareVersion,
  });

  final int id;
  final String name;
  final int? sceneId;
  final int? doorType;
  final String? doorTypeLabel;
  final int? controlSource;
  final String? controlSourceLabel;
  final int? controlMode;
  final String? controlModeLabel;
  final int? onlineStatus;
  final String? onlineStatusLabel;
  final int? doorState;
  final String? doorStateLabel;
  final double? positionPercent;
  final int? coverMode;
  final String? coverModeLabel;
  final int? coverFileId;
  final bool top;
  final String? sceneName;
  final int? operatedCycles;
  final int? remainingCycles;
  final String? hardwareSn;
  final String? model;
  final String? firmwareVersion;
  final String? hardwareVersion;

  factory DoorDetailResponseDto.fromJson(Map<String, dynamic> json) {
    return DoorDetailResponseDto(
      id: _parseInt(json['id']),
      name: json['name'] as String? ?? '',
      sceneId: _parseNullableInt(json['sceneId']),
      doorType: _parseNullableInt(json['doorType']),
      doorTypeLabel: json['doorTypeLabel'] as String?,
      controlSource: _parseNullableInt(json['controlSource']),
      controlSourceLabel: json['controlSourceLabel'] as String?,
      controlMode: _parseNullableInt(json['controlMode']),
      controlModeLabel: json['controlModeLabel'] as String?,
      onlineStatus: _parseNullableInt(json['onlineStatus']),
      onlineStatusLabel: json['onlineStatusLabel'] as String?,
      doorState: _parseNullableInt(json['doorState']),
      doorStateLabel: json['doorStateLabel'] as String?,
      positionPercent: _parseNullableDouble(json['positionPercent']),
      coverMode: _parseNullableInt(json['coverMode']),
      coverModeLabel: json['coverModeLabel'] as String?,
      coverFileId: _parseNullableInt(json['coverFileId']),
      top: json['top'] as bool? ?? false,
      sceneName: json['sceneName'] as String?,
      operatedCycles: _parseNullableInt(json['operatedCycles']),
      remainingCycles: _parseNullableInt(json['remainingCycles']),
      hardwareSn: json['hardwareSn'] as String?,
      model: json['model'] as String?,
      firmwareVersion: json['firmwareVersion'] as String?,
      hardwareVersion: json['hardwareVersion'] as String?,
    );
  }

  static int _parseInt(Object? value) {
    return _parseNullableInt(value) ?? 0;
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
