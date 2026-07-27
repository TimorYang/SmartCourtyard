typedef SessionExpiredHandler = Future<void> Function();

enum TokenRefreshResult { refreshed, sessionExpired }

typedef TokenRefreshHandler = Future<TokenRefreshResult> Function();

Future<void> ignoreSessionExpired() async {}

Future<TokenRefreshResult> noTokenRefreshAvailable() async {
  return TokenRefreshResult.sessionExpired;
}
