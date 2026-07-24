class GeneralEvaluationResponseDto {
  const GeneralEvaluationResponseDto({
    this.device,
    this.motorFunctions = const [],
  });
  final GeneralEvaluationDeviceDto? device;
  final List<MotorFunctionItemDto> motorFunctions;
  factory GeneralEvaluationResponseDto.fromJson(Map<String, dynamic> json) =>
      GeneralEvaluationResponseDto(
        device: json['device'] is Map<String, dynamic>
            ? GeneralEvaluationDeviceDto.fromJson(
                json['device'] as Map<String, dynamic>,
              )
            : null,
        motorFunctions: (json['motorFunctions'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MotorFunctionItemDto.fromJson)
            .toList(),
      );
  Map<String, dynamic> toJson() => {
    'device': device?.toJson(),
    'motorFunctions': motorFunctions.map((e) => e.toJson()).toList(),
  };
}

class GeneralEvaluationDeviceDto {
  const GeneralEvaluationDeviceDto({
    this.doorName,
    this.operatedCycles,
    this.remainingCycles,
    this.maintenanceRecommended,
  });
  final String? doorName;
  final int? operatedCycles;
  final int? remainingCycles;
  final bool? maintenanceRecommended;
  factory GeneralEvaluationDeviceDto.fromJson(Map<String, dynamic> json) =>
      GeneralEvaluationDeviceDto(
        doorName: json['doorName'] as String?,
        operatedCycles: _int(json['operatedCycles']),
        remainingCycles: _int(json['remainingCycles']),
        maintenanceRecommended: json['maintenanceRecommended'] as bool?,
      );
  Map<String, dynamic> toJson() => {
    'doorName': doorName,
    'operatedCycles': operatedCycles,
    'remainingCycles': remainingCycles,
    'maintenanceRecommended': maintenanceRecommended,
  };
}

class MotorFunctionItemDto {
  const MotorFunctionItemDto({this.settingCode, this.currentValue, this.unit});
  final int? settingCode;
  final int? currentValue;
  final String? unit;
  factory MotorFunctionItemDto.fromJson(Map<String, dynamic> j) =>
      MotorFunctionItemDto(
        settingCode: _int(j['settingCode']),
        currentValue: _int(j['currentValue']),
        unit: j['unit'] as String?,
      );
  Map<String, dynamic> toJson() => {
    'settingCode': settingCode,
    'currentValue': currentValue,
    'unit': unit,
  };
}

class BalanceResponseDto {
  const BalanceResponseDto({this.status, this.segments = const []});
  final String? status;
  final List<BalanceSegmentDto> segments;
  factory BalanceResponseDto.fromJson(Map<String, dynamic> j) =>
      BalanceResponseDto(
        status: j['status']?.toString(),
        segments: (j['segments'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BalanceSegmentDto.fromJson)
            .toList(),
      );
  Map<String, dynamic> toJson() => {
    'status': status,
    'segments': segments.map((e) => e.toJson()).toList(),
  };
}

class BalanceSegmentDto {
  const BalanceSegmentDto({
    this.direction,
    this.startPercent,
    this.endPercent,
    this.status,
  });
  final String? direction;
  final int? startPercent;
  final int? endPercent;
  final String? status;
  factory BalanceSegmentDto.fromJson(Map<String, dynamic> j) =>
      BalanceSegmentDto(
        direction: j['direction']?.toString(),
        startPercent: _int(j['startPercent']),
        endPercent: _int(j['endPercent']),
        status: j['status']?.toString(),
      );
  Map<String, dynamic> toJson() => {
    'direction': direction,
    'startPercent': startPercent,
    'endPercent': endPercent,
    'status': status,
  };
}

class OperationStatisticsDto {
  const OperationStatisticsDto({
    this.abnormal = false,
    this.buckets = const [],
  });
  final bool abnormal;
  final List<OperationBucketDto> buckets;
  factory OperationStatisticsDto.fromJson(Map<String, dynamic> j) =>
      OperationStatisticsDto(
        abnormal: j['abnormal'] as bool? ?? false,
        buckets: (j['buckets'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(OperationBucketDto.fromJson)
            .toList(),
      );
  Map<String, dynamic> toJson() => {
    'abnormal': abnormal,
    'buckets': buckets.map((e) => e.toJson()).toList(),
  };
}

class OperationBucketDto {
  const OperationBucketDto({
    this.hour,
    this.date,
    this.operationCycles,
    this.abnormal = false,
  });

  /// range=0 时对应图表 X 轴的小时；按 wire 约定以字符串容错接收。
  final String? hour;

  /// range=1 时对应图表 X 轴的日期；支持时间戳或日期字符串。
  final String? date;

  /// 对应当前小时/日期的运行次数；领域层再转换为 int。
  final String? operationCycles;
  final bool abnormal;
  factory OperationBucketDto.fromJson(Map<String, dynamic> j) =>
      OperationBucketDto(
        hour: j['hour']?.toString(),
        date: j['date']?.toString(),
        operationCycles: j['operationCycles']?.toString(),
        abnormal: j['abnormal'] as bool? ?? false,
      );
  Map<String, dynamic> toJson() => {
    'hour': hour,
    'date': date,
    'operationCycles': operationCycles,
    'abnormal': abnormal,
  };
}

int? _int(Object? v) => v is num
    ? v.toInt()
    : v is String
    ? int.tryParse(v)
    : null;
