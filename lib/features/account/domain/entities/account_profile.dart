class AccountProfile {
  AccountProfile({
    required String email,
    required String nickname,
    required this.registeredAt,
    this.avatarUrl,
    this.country,
  }) : email = normalizeEmail(email),
       nickname = nickname.trim();

  final String email;
  final String nickname;
  final String? avatarUrl;
  final DateTime registeredAt;
  final String? country;

  static String normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }

  AccountProfile copyWith({
    String? email,
    String? nickname,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    DateTime? registeredAt,
    String? country,
    bool clearCountry = false,
  }) {
    return AccountProfile(
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatarUrl: clearAvatarUrl ? null : avatarUrl ?? this.avatarUrl,
      registeredAt: registeredAt ?? this.registeredAt,
      country: clearCountry ? null : country ?? this.country,
    );
  }

  @override
  String toString() {
    return 'AccountProfile(email: $email, nickname: $nickname, '
        'avatarUrl: $avatarUrl, registeredAt: $registeredAt, '
        'country: $country)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AccountProfile &&
            other.email == email &&
            other.nickname == nickname &&
            other.avatarUrl == avatarUrl &&
            other.registeredAt == registeredAt &&
            other.country == country;
  }

  @override
  int get hashCode {
    return Object.hash(email, nickname, avatarUrl, registeredAt, country);
  }
}
