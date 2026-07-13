class OnboardingDeviceKey {
  const OnboardingDeviceKey({
    required this.sn,
    required this.aesKey,
    required this.aesKeyVersion,
  });

  final String sn;
  final String aesKey;
  final String aesKeyVersion;
}
