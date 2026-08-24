class AboutDeviceInfo {
  const AboutDeviceInfo({
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
}
