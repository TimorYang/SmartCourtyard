class AccountProfile {
  AccountProfile({
    required String userId,
    required String email,
    required String nickname,
    this.registeredAt,
    this.avatarUrl,
    this.avatarFileId,
    this.country,
  }) : userId = userId.trim(),
       email = normalizeEmail(email),
       nickname = nickname.trim();

  final String userId;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final int? avatarFileId;
  final DateTime? registeredAt;
  final String? country;

  static String normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }

  AccountProfile copyWith({
    String? userId,
    String? email,
    String? nickname,
    String? avatarUrl,
    int? avatarFileId,
    bool clearAvatarUrl = false,
    DateTime? registeredAt,
    String? country,
    bool clearCountry = false,
  }) {
    return AccountProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatarUrl: clearAvatarUrl ? null : avatarUrl ?? this.avatarUrl,
      avatarFileId: avatarFileId ?? this.avatarFileId,
      registeredAt: registeredAt ?? this.registeredAt,
      country: clearCountry ? null : country ?? this.country,
    );
  }

  @override
  String toString() {
    return 'AccountProfile(userId: $userId, email: $email, nickname: $nickname, '
        'avatarUrl: $avatarUrl, registeredAt: $registeredAt, '
        'country: $country)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AccountProfile &&
            other.userId == userId &&
            other.email == email &&
            other.nickname == nickname &&
            other.avatarUrl == avatarUrl &&
            other.avatarFileId == avatarFileId &&
            other.registeredAt == registeredAt &&
            other.country == country;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      email,
      nickname,
      avatarUrl,
      avatarFileId,
      registeredAt,
      country,
    );
  }
}
