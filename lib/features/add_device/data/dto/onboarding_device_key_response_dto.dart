class OnboardingDeviceKeyResponseDto {
  const OnboardingDeviceKeyResponseDto({
    required this.sn,
    required this.aesKey,
    required this.aesKeyVersion,
  });

  final String sn;
  final String aesKey;
  final String aesKeyVersion;

  factory OnboardingDeviceKeyResponseDto.fromJson(Map<String, dynamic> json) {
    return OnboardingDeviceKeyResponseDto(
      sn: json['sn'] as String? ?? '',
      aesKey: json['aesKey'] as String? ?? '',
      aesKeyVersion: json['aesKeyVersion'] as String? ?? '',
    );
  }

  bool get isValid => sn.trim().isNotEmpty && aesKey.trim().isNotEmpty;
}
