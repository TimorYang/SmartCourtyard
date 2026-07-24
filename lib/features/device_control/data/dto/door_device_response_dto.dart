class DoorDeviceResponseDto {
  const DoorDeviceResponseDto({
    required this.deviceId,
    required this.sn,
    required this.deviceType,
    this.deviceTypeLabel,
    this.onlineStatus,
    this.onlineStatusLabel,
    this.bleName,
    this.bleUuid,
    this.bleMac,
    this.bleConnectionStatus,
    this.bleConnectionStatusLabel,
    this.wifiConnectionStatus,
    this.wifiConnectionStatusLabel,
    this.capabilities = const [],
  });

  final String deviceId;
  final String sn;
  final String deviceType;
  final String? deviceTypeLabel;
  final int? onlineStatus;
  final String? onlineStatusLabel;
  final String? bleName;
  final String? bleUuid;
  final String? bleMac;
  final int? bleConnectionStatus;
  final String? bleConnectionStatusLabel;
  final int? wifiConnectionStatus;
  final String? wifiConnectionStatusLabel;
  final List<String> capabilities;

  factory DoorDeviceResponseDto.fromJson(Map<String, dynamic> json) {
    return DoorDeviceResponseDto(
      deviceId: json['deviceId']?.toString() ?? '',
      sn: json['sn'] as String? ?? '',
      deviceType: json['deviceType'] as String? ?? '',
      deviceTypeLabel: json['deviceTypeLabel'] as String?,
      onlineStatus: _parseNullableInt(json['onlineStatus']),
      onlineStatusLabel: json['onlineStatusLabel'] as String?,
      bleName: json['bleName'] as String?,
      bleUuid: json['bleUuid'] as String?,
      bleMac: json['bleMac'] as String?,
      bleConnectionStatus: _parseNullableInt(json['bleConnectionStatus']),
      bleConnectionStatusLabel: json['bleConnectionStatusLabel'] as String?,
      wifiConnectionStatus: _parseNullableInt(json['wifiConnectionStatus']),
      wifiConnectionStatusLabel: json['wifiConnectionStatusLabel'] as String?,
      capabilities: (json['capabilities'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
    );
  }

  static int? _parseNullableInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
