class ManagedLoginDeviceDto {
  const ManagedLoginDeviceDto({
    required this.sessionId,
    required this.deviceModel,
    required this.platform,
    required this.lastLoginTime,
    required this.currentDevice,
  });

  final String sessionId;
  final String? deviceModel;
  final String? platform;
  final DateTime? lastLoginTime;
  final bool currentDevice;

  factory ManagedLoginDeviceDto.fromJson(Map<String, dynamic> json) {
    return ManagedLoginDeviceDto(
      sessionId: json['sessionId']?.toString() ?? '',
      deviceModel: json['deviceModel'] as String?,
      platform: json['platform'] as String?,
      lastLoginTime: _parseTimestamp(json['lastLoginTime']),
      currentDevice: json['currentDevice'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'deviceModel': deviceModel,
    'platform': platform,
    'lastLoginTime': lastLoginTime?.millisecondsSinceEpoch,
    'currentDevice': currentDevice,
  };

  static DateTime? _parseTimestamp(Object? value) {
    final milliseconds = switch (value) {
      num() => value.toInt(),
      String() => int.tryParse(value),
      _ => null,
    };
    return milliseconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
}
