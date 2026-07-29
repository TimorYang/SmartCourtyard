/// A device that currently has an authenticated account session.
class ManagedLoginDevice {
  const ManagedLoginDevice({
    required this.sessionId,
    required this.deviceModel,
    required this.platform,
    required this.lastLoginTime,
    required this.currentDevice,
  });

  final String sessionId;
  final String? deviceModel;
  final ManagedLoginDevicePlatform platform;
  final DateTime? lastLoginTime;
  final bool currentDevice;
}

enum ManagedLoginDevicePlatform {
  ios,
  android,
  unknown;

  static ManagedLoginDevicePlatform fromWireValue(String? value) {
    return switch (value?.trim().toUpperCase()) {
      'IOS' => ManagedLoginDevicePlatform.ios,
      'ANDROID' => ManagedLoginDevicePlatform.android,
      _ => ManagedLoginDevicePlatform.unknown,
    };
  }
}
