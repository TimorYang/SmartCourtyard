class SecurityCenterConnectionStatusDto {
  const SecurityCenterConnectionStatusDto({this.wifiConnectionStatus});

  final String? wifiConnectionStatus;

  factory SecurityCenterConnectionStatusDto.fromJson(
    Map<String, dynamic> json,
  ) => SecurityCenterConnectionStatusDto(
    wifiConnectionStatus: json['wifiConnectionStatus']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'wifiConnectionStatus': wifiConnectionStatus,
  };
}
