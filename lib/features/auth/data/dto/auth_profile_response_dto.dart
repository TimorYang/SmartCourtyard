class AuthProfileResponseDto {
  const AuthProfileResponseDto({
    required this.userId,
    required this.email,
    required this.emailVerified,
    required this.nickname,
    required this.regionCode,
    required this.locale,
    required this.timezone,
    this.avatarFileId,
    this.telephone,
  });

  final String userId;
  final String email;
  final bool emailVerified;
  final String nickname;
  final int? avatarFileId;
  final String? telephone;
  final String? regionCode;
  final String? locale;
  final String? timezone;

  factory AuthProfileResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthProfileResponseDto(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      emailVerified: json['emailVerified'] as bool? ?? false,
      nickname: json['nickname'] as String? ?? '',
      avatarFileId: _intValue(json['avatarFileId']),
      telephone: json['telephone'] as String?,
      regionCode: json['regionCode'] as String?,
      locale: json['locale'] as String?,
      timezone: json['timezone'] as String?,
    );
  }
}

int? _intValue(Object? value) => value is num
    ? value.toInt()
    : value is String
    ? int.tryParse(value)
    : null;
