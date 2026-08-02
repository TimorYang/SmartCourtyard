class RemoteDoorCommandResponseDto {
  const RemoteDoorCommandResponseDto({
    required this.commandId,
    required this.doorId,
    required this.action,
    required this.status,
    this.commandType,
    this.stateConfirmationStatus,
    this.deviceResultCode,
    this.failureCategory,
    this.failureReason,
    this.createdAt,
    this.publishedAt,
    this.deviceAckAt,
    this.stateReportedAt,
  });

  final String commandId;
  final String doorId;
  final String action;
  final String status;
  final String? commandType;
  final String? stateConfirmationStatus;
  final int? deviceResultCode;
  final String? failureCategory;
  final String? failureReason;
  final int? createdAt;
  final int? publishedAt;
  final int? deviceAckAt;
  final int? stateReportedAt;

  factory RemoteDoorCommandResponseDto.fromJson(Map<String, dynamic> json) {
    return RemoteDoorCommandResponseDto(
      commandId: _string(json['commandId']),
      doorId: _string(json['doorId']),
      commandType: _nullableString(json['commandType']),
      action: _string(json['action']),
      status: _string(json['status']),
      stateConfirmationStatus: _nullableString(json['stateConfirmationStatus']),
      deviceResultCode: _nullableInt(json['deviceResultCode']),
      failureCategory: _nullableString(json['failureCategory']),
      failureReason: _nullableString(json['failureReason']),
      createdAt: _nullableInt(json['createdAt']),
      publishedAt: _nullableInt(json['publishedAt']),
      deviceAckAt: _nullableInt(json['deviceAckAt']),
      stateReportedAt: _nullableInt(json['stateReportedAt']),
    );
  }

  static String _string(Object? value) => value?.toString() ?? '';

  static String? _nullableString(Object? value) {
    final parsed = value?.toString().trim();
    return parsed == null || parsed.isEmpty ? null : parsed;
  }

  static int? _nullableInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return value is String ? int.tryParse(value) : null;
  }
}
