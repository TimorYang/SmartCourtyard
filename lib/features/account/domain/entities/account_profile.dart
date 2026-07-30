import 'account_avatar_code.dart';

class AccountProfile {
  AccountProfile({
    required String userId,
    required String email,
    required String nickname,
    this.registeredAt,
    this.avatarUrl,
    this.avatarCode,
    this.avatarFileId,
    this.country,
    this.regionCode,
    this.locale,
    this.telephone,
    this.timezone,
  }) : userId = userId.trim(),
       email = normalizeEmail(email),
       nickname = nickname.trim();

  final String userId;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final AccountAvatarCode? avatarCode;
  final int? avatarFileId;
  final DateTime? registeredAt;
  final String? country;
  final String? regionCode;
  final String? locale;
  final String? telephone;
  final String? timezone;

  static String normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }

  AccountProfile copyWith({
    String? userId,
    String? email,
    String? nickname,
    String? avatarUrl,
    AccountAvatarCode? avatarCode,
    bool clearAvatarCode = false,
    int? avatarFileId,
    bool clearAvatarFileId = false,
    bool clearAvatarUrl = false,
    DateTime? registeredAt,
    String? country,
    bool clearCountry = false,
    String? regionCode,
    bool clearRegionCode = false,
    String? locale,
    bool clearLocale = false,
    String? telephone,
    bool clearTelephone = false,
    String? timezone,
    bool clearTimezone = false,
  }) {
    return AccountProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatarUrl: clearAvatarUrl ? null : avatarUrl ?? this.avatarUrl,
      avatarCode: clearAvatarCode ? null : avatarCode ?? this.avatarCode,
      avatarFileId: clearAvatarFileId
          ? null
          : avatarFileId ?? this.avatarFileId,
      registeredAt: registeredAt ?? this.registeredAt,
      country: clearCountry ? null : country ?? this.country,
      regionCode: clearRegionCode ? null : regionCode ?? this.regionCode,
      locale: clearLocale ? null : locale ?? this.locale,
      telephone: clearTelephone ? null : telephone ?? this.telephone,
      timezone: clearTimezone ? null : timezone ?? this.timezone,
    );
  }

  @override
  String toString() {
    return 'AccountProfile(userId: $userId, email: $email, nickname: $nickname, '
        'avatarUrl: $avatarUrl, registeredAt: $registeredAt, '
        'country: $country, regionCode: $regionCode, locale: $locale)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AccountProfile &&
            other.userId == userId &&
            other.email == email &&
            other.nickname == nickname &&
            other.avatarUrl == avatarUrl &&
            other.avatarCode == avatarCode &&
            other.avatarFileId == avatarFileId &&
            other.registeredAt == registeredAt &&
            other.country == country &&
            other.regionCode == regionCode &&
            other.locale == locale &&
            other.telephone == telephone &&
            other.timezone == timezone;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      email,
      nickname,
      avatarUrl,
      avatarCode,
      avatarFileId,
      registeredAt,
      country,
      regionCode,
      locale,
      telephone,
      timezone,
    );
  }
}
