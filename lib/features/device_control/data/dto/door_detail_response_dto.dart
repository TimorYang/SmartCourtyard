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
    this.operatedCycles,
    this.remainingCycles,
    this.associatedDevices = const [],
  });

  final int id;
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
  final int? operatedCycles;
  final int? remainingCycles;
  final List<DoorAssociatedDeviceResponseDto> associatedDevices;

  factory DoorDetailResponseDto.fromJson(Map<String, dynamic> json) {
    return DoorDetailResponseDto(
      id: _parseInt(json['id']),
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
      operatedCycles: _parseNullableInt(json['operatedCycles']),
      remainingCycles: _parseNullableInt(json['remainingCycles']),
      associatedDevices: (json['associatedDevices'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DoorAssociatedDeviceResponseDto.fromJson)
          .toList(),
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

class DoorAssociatedDeviceResponseDto {
  const DoorAssociatedDeviceResponseDto({
    this.deviceType,
    this.deviceTypeLabel,
    this.associated = false,
    this.primaryControl = false,
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
  final bool associated;
  final bool primaryControl;
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

  factory DoorAssociatedDeviceResponseDto.fromJson(Map<String, dynamic> json) {
    return DoorAssociatedDeviceResponseDto(
      deviceType: json['deviceType'] as String?,
      deviceTypeLabel: json['deviceTypeLabel'] as String?,
      associated: json['associated'] as bool? ?? false,
      primaryControl: json['primaryControl'] as bool? ?? false,
      onlineStatus: DoorDetailResponseDto._parseNullableInt(
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
