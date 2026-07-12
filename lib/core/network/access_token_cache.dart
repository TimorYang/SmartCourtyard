class AccessTokenCache {
  const AccessTokenCache._();

  static String? _accessToken;

  static String? get value => _accessToken;

  static void set(String token) {
    final trimmed = token.trim();
    _accessToken = trimmed.isEmpty ? null : trimmed;
  }

  static void clear() {
    _accessToken = null;
  }
}
