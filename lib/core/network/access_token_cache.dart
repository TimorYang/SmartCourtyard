class AccessTokenCache {
  const AccessTokenCache._();

  static String? _accessToken;
  static DateTime? _accessTokenExpiresAt;

  static String? get value => _accessToken;

  static bool get requiresRefresh {
    final expiry = _accessTokenExpiresAt;
    return _accessToken != null &&
        expiry != null &&
        !expiry.isAfter(DateTime.now().toUtc());
  }

  static void set(String token, {DateTime? expiresAt}) {
    final trimmed = token.trim();
    _accessToken = trimmed.isEmpty ? null : trimmed;
    _accessTokenExpiresAt = _accessToken == null ? null : expiresAt?.toUtc();
  }

  static void clear() {
    _accessToken = null;
    _accessTokenExpiresAt = null;
  }
}
