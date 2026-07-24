class SecurityCenterConnectionStatus {
  const SecurityCenterConnectionStatus({required this.wifiConnectionStatus});

  final String wifiConnectionStatus;

  bool get isWifiDisconnected => wifiConnectionStatus == '1';
}
