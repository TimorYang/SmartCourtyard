class ForceDoorResponseDto {
  const ForceDoorResponseDto({
    required this.id,
    this.name,
    this.doorType,
    this.doorTypeLabel,
    this.controlMode,
    this.controlModeLabel,
    this.onlineStatus,
    this.onlineStatusLabel,
    this.doorState,
    this.doorStateLabel,
    this.positionPercent,
    this.operatedCycles,
    this.remainingCycles,
    this.coverFileId,
    this.associatedDevices = const [],
  });

  final int id;
  final String? name;
  final int? doorType;
  final String? doorTypeLabel;
  final int? controlMode;
  final String? controlModeLabel;
  final int? onlineStatus;
  final String? onlineStatusLabel;
  final int? doorState;
  final String? doorStateLabel;
  final int? positionPercent;
  final int? operatedCycles;
  final int? remainingCycles;
  final int? coverFileId;
  final List<ForceDoorAssociatedDeviceDto> associatedDevices;

  factory ForceDoorResponseDto.fromJson(Map<String, dynamic> json) {
    return ForceDoorResponseDto(
      id: _parseInt(json['id']),
      name: json['name'] as String?,
      doorType: _parseNullableInt(json['doorType']),
      doorTypeLabel: json['doorTypeLabel'] as String?,
      controlMode: _parseNullableInt(json['controlMode']),
      controlModeLabel: json['controlModeLabel'] as String?,
      onlineStatus: _parseNullableInt(json['onlineStatus']),
      onlineStatusLabel: json['onlineStatusLabel'] as String?,
      doorState: _parseNullableInt(json['doorState']),
      doorStateLabel: json['doorStateLabel'] as String?,
      positionPercent: _parseNullableInt(json['positionPercent']),
      operatedCycles: _parseNullableInt(json['operatedCycles']),
      remainingCycles: _parseNullableInt(json['remainingCycles']),
      coverFileId: _parseNullableInt(json['coverFileId']),
      associatedDevices: (json['associatedDevices'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ForceDoorAssociatedDeviceDto.fromJson)
          .toList(),
    );
  }

  bool get isValid => id > 0;

  static int _parseInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static int? _parseNullableInt(Object? value) =>
      value == null ? null : _parseInt(value);
}

class ForceDoorAssociatedDeviceDto {
  const ForceDoorAssociatedDeviceDto({
    this.deviceType,
    this.deviceTypeLabel,
    this.associated,
    this.primaryControl,
    this.onlineStatus,
    this.onlineStatusLabel,
    this.bleName,
    this.bleUuid,
    this.bleMac,
    this.bleConnectionStatus,
    this.bleConnectionStatusLabel,
    this.wifiConnectionStatus,
    this.wifiConnectionStatusLabel,
    this.ledStatus,
    this.ledStatusLabel,
    this.capabilities = const [],
  });

  final String? deviceType;
  final String? deviceTypeLabel;
  final bool? associated;
  final bool? primaryControl;
  final int? onlineStatus;
  final String? onlineStatusLabel;
  final String? bleName;
  final String? bleUuid;
  final String? bleMac;
  final String? bleConnectionStatus;
  final String? bleConnectionStatusLabel;
  final String? wifiConnectionStatus;
  final String? wifiConnectionStatusLabel;
  final String? ledStatus;
  final String? ledStatusLabel;
  final List<String> capabilities;

  factory ForceDoorAssociatedDeviceDto.fromJson(Map<String, dynamic> json) {
    return ForceDoorAssociatedDeviceDto(
      deviceType: json['deviceType'] as String?,
      deviceTypeLabel: json['deviceTypeLabel'] as String?,
      associated: json['associated'] as bool?,
      primaryControl: json['primaryControl'] as bool?,
      onlineStatus: ForceDoorResponseDto._parseNullableInt(
        json['onlineStatus'],
      ),
      onlineStatusLabel: json['onlineStatusLabel'] as String?,
      bleName: json['bleName'] as String?,
      bleUuid: json['bleUuid'] as String?,
      bleMac: json['bleMac'] as String?,
      bleConnectionStatus: json['bleConnectionStatus'] as String?,
      bleConnectionStatusLabel: json['bleConnectionStatusLabel'] as String?,
      wifiConnectionStatus: json['wifiConnectionStatus'] as String?,
      wifiConnectionStatusLabel: json['wifiConnectionStatusLabel'] as String?,
      ledStatus: json['ledStatus'] as String?,
      ledStatusLabel: json['ledStatusLabel'] as String?,
      capabilities: (json['capabilities'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
    );
  }
}
