class HomeDoorResponseDto {
  const HomeDoorResponseDto({
    required this.id,
    required this.name,
    required this.sceneId,
    this.controlMode,
    this.controlModeLabel,
    this.controlSource,
    this.controlSourceLabel,
    this.coverFileId,
    this.coverMode,
    this.coverModeLabel,
    this.doorState,
    this.doorStateLabel,
    this.doorType,
    this.doorTypeLabel,
    this.onlineStatus,
    this.onlineStatusLabel,
    this.positionPercent,
    this.shareStatus,
    this.shareStatusLabel,
    this.hasBoundDevices = false,
    this.top = false,
  });

  final int id;
  final String name;
  final int sceneId;
  final int? controlMode;
  final String? controlModeLabel;
  final int? controlSource;
  final String? controlSourceLabel;
  final int? coverFileId;
  final int? coverMode;
  final String? coverModeLabel;
  final int? doorState;
  final String? doorStateLabel;
  final int? doorType;
  final String? doorTypeLabel;
  final int? onlineStatus;
  final String? onlineStatusLabel;
  final double? positionPercent;
  final int? shareStatus;
  final String? shareStatusLabel;
  final bool hasBoundDevices;
  final bool top;

  factory HomeDoorResponseDto.fromJson(Map<String, dynamic> json) {
    return HomeDoorResponseDto(
      id: _parseInt(json['id']),
      name: json['name'] as String? ?? '',
      sceneId: _parseInt(json['sceneId']),
      controlMode: _parseNullableInt(json['controlMode']),
      controlModeLabel: json['controlModeLabel'] as String?,
      controlSource: _parseNullableInt(json['controlSource']),
      controlSourceLabel: json['controlSourceLabel'] as String?,
      coverFileId: _parseNullableInt(json['coverFileId']),
      coverMode: _parseNullableInt(json['coverMode']),
      coverModeLabel: json['coverModeLabel'] as String?,
      doorState: _parseNullableInt(json['doorState']),
      doorStateLabel: json['doorStateLabel'] as String?,
      doorType: _parseNullableInt(json['doorType']),
      doorTypeLabel: json['doorTypeLabel'] as String?,
      onlineStatus: _parseNullableInt(json['onlineStatus']),
      onlineStatusLabel: json['onlineStatusLabel'] as String?,
      positionPercent: _parseNullableDouble(json['positionPercent']),
      shareStatus: _parseNullableInt(json['shareStatus']),
      shareStatusLabel: json['shareStatusLabel'] as String?,
      hasBoundDevices: json['hasBoundDevices'] as bool? ?? false,
      top: json['top'] as bool? ?? false,
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
