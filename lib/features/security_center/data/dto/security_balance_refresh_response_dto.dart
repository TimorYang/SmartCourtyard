class SecurityBalanceRefreshResponseDto {
  const SecurityBalanceRefreshResponseDto({
    this.requestId,
    this.status,
    this.statusLabel,
    this.requestedAt,
    this.msg,
  });

  final String? requestId;
  final String? status;
  final String? statusLabel;
  final int? requestedAt;
  final String? msg;

  factory SecurityBalanceRefreshResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return SecurityBalanceRefreshResponseDto(
      requestId: json['requestId'] as String?,
      status: json['status']?.toString(),
      statusLabel: json['statusLabel'] as String?,
      requestedAt: _parseNullableInt(json['requestedAt']),
      msg: json['msg'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'status': status,
    'statusLabel': statusLabel,
    'requestedAt': requestedAt,
    'msg': msg,
  };

  static int? _parseNullableInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
