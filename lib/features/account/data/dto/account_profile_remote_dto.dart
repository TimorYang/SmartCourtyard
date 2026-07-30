class AccountProfileRemoteDto {
  const AccountProfileRemoteDto({
    required this.userId,
    required this.email,
    required this.emailVerified,
    required this.nickname,
    this.avatarCode,
    this.avatarFileId,
    this.telephone,
    this.regionCode,
    this.locale,
    this.timezone,
  });

  final String userId;
  final String email;
  final bool emailVerified;
  final String nickname;
  final String? avatarCode;
  final int? avatarFileId;
  final String? telephone;
  final String? regionCode;
  final String? locale;
  final String? timezone;

  factory AccountProfileRemoteDto.fromJson(Map<String, dynamic> json) {
    return AccountProfileRemoteDto(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      emailVerified: json['emailVerified'] as bool? ?? false,
      nickname: json['nickname'] as String? ?? '',
      avatarCode: json['avatarCode'] as String?,
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
