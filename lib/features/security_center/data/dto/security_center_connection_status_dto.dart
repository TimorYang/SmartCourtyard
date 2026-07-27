class SecurityCenterConnectionStatusDto {
  const SecurityCenterConnectionStatusDto({
    this.wifiConnectionStatus,
    this.sensorStatus,
    this.wiredSensors = const [],
    this.wirelessSensors = const [],
  });

  final String? wifiConnectionStatus;
  final String? sensorStatus;
  final List<SecurityCenterSensorStatusItemDto> wiredSensors;
  final List<SecurityCenterSensorStatusItemDto> wirelessSensors;

  factory SecurityCenterConnectionStatusDto.fromJson(
    Map<String, dynamic> json,
  ) => SecurityCenterConnectionStatusDto(
    wifiConnectionStatus: json['wifiConnectionStatus']?.toString(),
    sensorStatus: json['sensorStatus']?.toString(),
    wiredSensors: _sensorItemsFromJson(json['wiredSensors']),
    wirelessSensors: _sensorItemsFromJson(json['wirelessSensors']),
  );

  Map<String, dynamic> toJson() => {
    'wifiConnectionStatus': wifiConnectionStatus,
    'sensorStatus': sensorStatus,
    'wiredSensors': wiredSensors.map((sensor) => sensor.toJson()).toList(),
    'wirelessSensors': wirelessSensors
        .map((sensor) => sensor.toJson())
        .toList(),
  };

  static List<SecurityCenterSensorStatusItemDto> _sensorItemsFromJson(
    Object? value,
  ) {
    if (value is! List<Object?>) return const [];
    return [
      for (final item in value)
        if (item is Map<Object?, Object?>)
          SecurityCenterSensorStatusItemDto.fromJson(
            Map<String, dynamic>.from(item),
          ),
    ];
  }
}

class SecurityCenterSensorStatusItemDto {
  const SecurityCenterSensorStatusItemDto({
    this.sensorCode,
    this.status,
    this.batteryStatus,
  });

  final String? sensorCode;
  final String? status;
  final String? batteryStatus;

  factory SecurityCenterSensorStatusItemDto.fromJson(
    Map<String, dynamic> json,
  ) => SecurityCenterSensorStatusItemDto(
    sensorCode: json['sensorCode']?.toString(),
    status: json['status']?.toString(),
    batteryStatus: json['batteryStatus']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'sensorCode': sensorCode,
    'status': status,
    'batteryStatus': batteryStatus,
  };
}
