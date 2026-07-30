class AccountRemoteDto {
  const AccountRemoteDto({
    required this.userId,
    required this.email,
    required this.nickname,
    required this.registeredAtIso8601,
    this.avatarUrl,
    this.avatarCode,
    this.country,
  });

  final String userId;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final String? avatarCode;
  final String registeredAtIso8601;
  final String? country;

  factory AccountRemoteDto.fromJson(Map<String, Object?> json) {
    return AccountRemoteDto(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      avatarCode: json['avatarCode'] as String?,
      registeredAtIso8601: json['registeredAt'] as String? ?? '',
      country: json['country'] as String?,
    );
  }
}
