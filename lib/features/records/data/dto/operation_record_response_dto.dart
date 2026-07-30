class OperationRecordResponseDto {
  const OperationRecordResponseDto({
    this.id,
    this.commandId,
    this.action,
    this.operationSource,
    this.doorName,
    this.operatorUserId,
    this.operatorName,
    this.operatorAccount,
    this.operatorAvatarCode,
    this.operatorAvatarFileId,
    this.operationMethod,
    this.operationMethodLabel,
    this.sourceDeviceName,
    this.sourceDeviceType,
    this.fromState,
    this.toState,
    this.positionPercent,
    this.faultCode,
    this.occurredAt,
  });

  final int? id;
  final String? commandId;
  final String? action;
  final String? operationSource;
  final String? doorName;
  final int? operatorUserId;
  final String? operatorName;
  final String? operatorAccount;
  final String? operatorAvatarCode;
  final int? operatorAvatarFileId;
  final String? operationMethod;
  final String? operationMethodLabel;
  final String? sourceDeviceName;
  final String? sourceDeviceType;
  final int? fromState;
  final int? toState;
  final double? positionPercent;
  final String? faultCode;
  final int? occurredAt;

  factory OperationRecordResponseDto.fromJson(Map<String, dynamic> json) {
    return OperationRecordResponseDto(
      id: _intValue(json['id']),
      commandId: json['commandId'] as String?,
      action: json['action'] as String?,
      operationSource: json['operationSource'] as String?,
      doorName: json['doorName'] as String?,
      operatorUserId: _intValue(json['operatorUserId']),
      operatorName: json['operatorName'] as String?,
      operatorAccount: json['operatorAccount'] as String?,
      operatorAvatarCode: json['operatorAvatarCode'] as String?,
      operatorAvatarFileId: _intValue(json['operatorAvatarFileId']),
      operationMethod: json['operationMethod'] as String?,
      operationMethodLabel: json['operationMethodLabel'] as String?,
      sourceDeviceName: json['sourceDeviceName'] as String?,
      sourceDeviceType: json['sourceDeviceType'] as String?,
      fromState: _intValue(json['fromState']),
      toState: _intValue(json['toState']),
      positionPercent: _doubleValue(json['positionPercent']),
      faultCode: json['faultCode'] as String?,
      occurredAt: _intValue(json['occurredAt']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'commandId': commandId,
    'action': action,
    'operationSource': operationSource,
    'doorName': doorName,
    'operatorUserId': operatorUserId,
    'operatorName': operatorName,
    'operatorAccount': operatorAccount,
    'operatorAvatarCode': operatorAvatarCode,
    'operatorAvatarFileId': operatorAvatarFileId,
    'operationMethod': operationMethod,
    'operationMethodLabel': operationMethodLabel,
    'sourceDeviceName': sourceDeviceName,
    'sourceDeviceType': sourceDeviceType,
    'fromState': fromState,
    'toState': toState,
    'positionPercent': positionPercent,
    'faultCode': faultCode,
    'occurredAt': occurredAt,
  };
}

class OperationRecordPageResponseDto {
  const OperationRecordPageResponseDto({
    this.current,
    this.size,
    this.total,
    this.records = const <OperationRecordResponseDto>[],
  });

  final int? current;
  final int? size;
  final int? total;
  final List<OperationRecordResponseDto> records;

  factory OperationRecordPageResponseDto.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'];
    return OperationRecordPageResponseDto(
      current: _intValue(json['current']),
      size: _intValue(json['size']),
      total: _intValue(json['total']),
      records: rawRecords is List
          ? rawRecords
                .whereType<Map>()
                .map(
                  (item) => OperationRecordResponseDto.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <OperationRecordResponseDto>[],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'current': current,
    'size': size,
    'total': total,
    'records': records.map((record) => record.toJson()).toList(),
  };
}

int? _intValue(Object? value) => switch (value) {
  final num number => number.toInt(),
  final String text => int.tryParse(text),
  _ => null,
};

double? _doubleValue(Object? value) => switch (value) {
  final num number => number.toDouble(),
  final String text => double.tryParse(text),
  _ => null,
};
