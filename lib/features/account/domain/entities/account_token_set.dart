class AccountTokenSet {
  const AccountTokenSet({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.tokenType = 'Bearer',
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String tokenType;

  bool get hasAccessToken => accessToken.trim().isNotEmpty;

  @override
  String toString() {
    return 'AccountTokenSet(accessToken: <redacted>, '
        'refreshToken: ${refreshToken == null ? null : '<redacted>'}, '
        'expiresAt: $expiresAt, tokenType: $tokenType)';
  }
}
