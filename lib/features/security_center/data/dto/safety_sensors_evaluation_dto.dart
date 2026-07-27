class SafetySensorsEvaluationDto {
  const SafetySensorsEvaluationDto({
    this.doorName,
    this.sensorCount,
    this.normalCount,
    this.abnormalCount,
    this.lowBatteryCount,
    this.statisticsStartTime,
    this.statisticsEndTime,
    this.wiredSensors = const [],
    this.wirelessSensors = const [],
  });

  final String? doorName;
  final int? sensorCount;
  final int? normalCount;
  final int? abnormalCount;
  final int? lowBatteryCount;
  final int? statisticsStartTime;
  final int? statisticsEndTime;
  final List<SafetySensorItemDto> wiredSensors;
  final List<SafetySensorItemDto> wirelessSensors;

  factory SafetySensorsEvaluationDto.fromJson(Map<String, dynamic> json) =>
      SafetySensorsEvaluationDto(
        doorName: json['doorName'] as String?,
        sensorCount: _asInt(json['sensorCount']),
        normalCount: _asInt(json['normalCount']),
        abnormalCount: _asInt(json['abnormalCount']),
        lowBatteryCount: _asInt(json['lowBatteryCount']),
        statisticsStartTime: _asInt(json['statisticsStartTime']),
        statisticsEndTime: _asInt(json['statisticsEndTime']),
        wiredSensors: _sensors(json['wiredSensors']),
        wirelessSensors: _sensors(json['wirelessSensors']),
      );

  Map<String, dynamic> toJson() => {
    'doorName': doorName,
    'sensorCount': sensorCount,
    'normalCount': normalCount,
    'abnormalCount': abnormalCount,
    'lowBatteryCount': lowBatteryCount,
    'statisticsStartTime': statisticsStartTime,
    'statisticsEndTime': statisticsEndTime,
    'wiredSensors': wiredSensors.map((sensor) => sensor.toJson()).toList(),
    'wirelessSensors': wirelessSensors.map((sensor) => sensor.toJson()).toList(),
  };
}

class SafetySensorItemDto {
  const SafetySensorItemDto({
    this.sensorCode,
    this.sensorCodeLabel,
    this.status,
    this.statusLabel,
    this.batteryStatus,
    this.batteryStatusLabel,
    this.triggerBuckets = const [],
  });

  final String? sensorCode;
  final String? sensorCodeLabel;
  final String? status;
  final String? statusLabel;
  final String? batteryStatus;
  final String? batteryStatusLabel;
  final List<SafetySensorTriggerBucketDto> triggerBuckets;

  factory SafetySensorItemDto.fromJson(Map<String, dynamic> json) =>
      SafetySensorItemDto(
        sensorCode: json['sensorCode']?.toString(),
        sensorCodeLabel: json['sensorCodeLabel'] as String?,
        status: json['status']?.toString(),
        statusLabel: json['statusLabel'] as String?,
        batteryStatus: json['batteryStatus']?.toString(),
        batteryStatusLabel: json['batteryStatusLabel'] as String?,
        triggerBuckets: _buckets(json['triggerBuckets']),
      );

  Map<String, dynamic> toJson() => {
    'sensorCode': sensorCode,
    'sensorCodeLabel': sensorCodeLabel,
    'status': status,
    'statusLabel': statusLabel,
    'batteryStatus': batteryStatus,
    'batteryStatusLabel': batteryStatusLabel,
    'triggerBuckets': triggerBuckets.map((bucket) => bucket.toJson()).toList(),
  };
}

class SafetySensorTriggerBucketDto {
  const SafetySensorTriggerBucketDto({
    this.hour,
    this.triggerCount,
    this.abnormal,
  });

  final int? hour;
  final int? triggerCount;
  final bool? abnormal;

  factory SafetySensorTriggerBucketDto.fromJson(Map<String, dynamic> json) =>
      SafetySensorTriggerBucketDto(
        hour: _asInt(json['hour']),
        triggerCount: _asInt(json['triggerCount']),
        abnormal: json['abnormal'] as bool?,
      );

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'triggerCount': triggerCount,
    'abnormal': abnormal,
  };
}

int? _asInt(Object? value) => value is num
    ? value.toInt()
    : value is String
    ? int.tryParse(value)
    : null;

List<SafetySensorItemDto> _sensors(Object? value) => value is List
    ? value
        .whereType<Map>()
        .map((item) => SafetySensorItemDto.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false)
    : const [];

List<SafetySensorTriggerBucketDto> _buckets(Object? value) => value is List
    ? value
        .whereType<Map>()
        .map((item) => SafetySensorTriggerBucketDto.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false)
    : const [];
