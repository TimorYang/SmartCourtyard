class LoginDeviceContext {
  const LoginDeviceContext({
    required this.deviceId,
    required this.deviceModel,
    required this.platform,
    required this.appVersion,
  });

  final String deviceId;
  final String deviceModel;
  final String platform;
  final String appVersion;
}
