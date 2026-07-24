class DoorDevice {
  const DoorDevice({
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

  bool get isOnline => onlineStatus == 1;
  bool get isBleConnected => bleConnectionStatus == 2;
  bool get isWifiConnected => wifiConnectionStatus == 2;
}
