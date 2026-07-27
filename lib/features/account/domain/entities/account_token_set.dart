class AccountTokenSet {
  const AccountTokenSet({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.refreshExpiresAt,
    this.tokenType = 'Bearer',
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final DateTime? refreshExpiresAt;
  final String tokenType;

  bool get hasAccessToken => accessToken.trim().isNotEmpty;

  bool isUsableAt(DateTime now) {
    if (!hasAccessToken) {
      return false;
    }

    final expiry = expiresAt;
    return expiry == null || expiry.isAfter(now.toUtc());
  }

  bool get hasRefreshToken => (refreshToken ?? '').trim().isNotEmpty;

  bool isRefreshUsableAt(DateTime now) {
    if (!hasRefreshToken) {
      return false;
    }

    final expiry = refreshExpiresAt;
    return expiry != null && expiry.isAfter(now.toUtc());
  }

  @override
  String toString() {
    return 'AccountTokenSet(accessToken: <redacted>, '
        'refreshToken: ${refreshToken == null ? null : '<redacted>'}, '
        'expiresAt: $expiresAt, tokenType: $tokenType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AccountTokenSet &&
            other.accessToken == accessToken &&
            other.refreshToken == refreshToken &&
            other.expiresAt == expiresAt &&
            other.refreshExpiresAt == refreshExpiresAt &&
            other.tokenType == tokenType;
  }

  @override
  int get hashCode {
    return Object.hash(
      accessToken,
      refreshToken,
      expiresAt,
      refreshExpiresAt,
      tokenType,
    );
  }
}
