class AccountProfileDto {
  const AccountProfileDto({
    required this.schemaVersion,
    required this.userId,
    required this.email,
    required this.nickname,
    required this.registeredAtIso8601,
    this.avatarUrl,
    this.avatarCode,
    this.avatarFileId,
    this.country,
    this.regionCode,
    this.locale,
    this.telephone,
    this.timezone,
  });

  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final String userId;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final String? avatarCode;
  final int? avatarFileId;
  final String registeredAtIso8601;
  final String? country;
  final String? regionCode;
  final String? locale;
  final String? telephone;
  final String? timezone;

  factory AccountProfileDto.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion'] as int? ?? currentSchemaVersion;
    return AccountProfileDto(
      schemaVersion: schemaVersion,
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      avatarCode: json['avatarCode'] as String?,
      avatarFileId: _intValue(json['avatarFileId']),
      registeredAtIso8601: json['registeredAt'] as String? ?? '',
      country: json['country'] as String?,
      regionCode:
          json['regionCode'] as String? ??
          (schemaVersion < currentSchemaVersion
              ? json['country'] as String?
              : null),
      locale: json['locale'] as String?,
      telephone: json['telephone'] as String?,
      timezone: json['timezone'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'userId': userId,
      'email': email,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'avatarCode': avatarCode,
      'avatarFileId': avatarFileId,
      'registeredAt': registeredAtIso8601,
      'country': country,
      'regionCode': regionCode,
      'locale': locale,
      'telephone': telephone,
      'timezone': timezone,
    };
  }
}

int? _intValue(Object? value) => value is num
    ? value.toInt()
    : value is String
    ? int.tryParse(value)
    : null;
