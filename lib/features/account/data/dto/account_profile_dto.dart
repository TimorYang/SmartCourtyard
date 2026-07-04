class AccountProfileDto {
  const AccountProfileDto({
    required this.schemaVersion,
    required this.email,
    required this.nickname,
    required this.registeredAtIso8601,
    this.avatarUrl,
    this.country,
  });

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final String registeredAtIso8601;
  final String? country;

  factory AccountProfileDto.fromJson(Map<String, Object?> json) {
    return AccountProfileDto(
      schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      registeredAtIso8601: json['registeredAt'] as String? ?? '',
      country: json['country'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'email': email,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'registeredAt': registeredAtIso8601,
      'country': country,
    };
  }
}
