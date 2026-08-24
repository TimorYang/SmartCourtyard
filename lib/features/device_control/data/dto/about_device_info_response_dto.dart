class AboutDeviceInfoResponseDto {
  const AboutDeviceInfoResponseDto({
    required this.deviceId,
    required this.sn,
    required this.deviceType,
    required this.deviceTypeLabel,
    required this.bluetoothName,
    required this.hardwareVersion,
    required this.firmwareVersion,
    required this.updateAvailable,
    required this.availableVersion,
  });

  final String deviceId;
  final String sn;
  final String deviceType;
  final String deviceTypeLabel;
  final String bluetoothName;
  final String hardwareVersion;
  final String firmwareVersion;
  final bool updateAvailable;
  final String availableVersion;

  factory AboutDeviceInfoResponseDto.fromJson(Map<String, dynamic> json) {
    return AboutDeviceInfoResponseDto(
      deviceId: json['deviceId']?.toString() ?? '',
      sn: json['sn']?.toString() ?? '',
      deviceType: json['deviceType']?.toString() ?? '',
      deviceTypeLabel: json['deviceTypeLabel']?.toString() ?? '',
      bluetoothName: json['bluetoothName']?.toString() ?? '',
      hardwareVersion: json['hardwareVersion']?.toString() ?? '',
      firmwareVersion: json['firmwareVersion']?.toString() ?? '',
      updateAvailable: json['updateAvailable'] as bool? ?? false,
      availableVersion: json['availableVersion']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'sn': sn,
    'deviceType': deviceType,
    'deviceTypeLabel': deviceTypeLabel,
    'bluetoothName': bluetoothName,
    'hardwareVersion': hardwareVersion,
    'firmwareVersion': firmwareVersion,
    'updateAvailable': updateAvailable,
    'availableVersion': availableVersion,
  };
}
