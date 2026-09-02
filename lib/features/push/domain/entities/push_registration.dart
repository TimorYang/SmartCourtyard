enum PushPlatform {
  ios('IOS'),
  android('ANDROID');

  const PushPlatform(this.wireValue);

  final String wireValue;

  static PushPlatform? fromWireValue(String value) {
    final normalized = value.trim().toUpperCase();
    for (final platform in values) {
      if (platform.wireValue == normalized) return platform;
    }
    return null;
  }
}

class PushRegistration {
  const PushRegistration({
    required this.registrationId,
    required this.deviceId,
    required this.platform,
  });

  final String registrationId;
  final String deviceId;
  final PushPlatform platform;
}
