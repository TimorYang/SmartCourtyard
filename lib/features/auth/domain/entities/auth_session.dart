class AuthSession {
  const AuthSession({
    required this.isAuthenticated,
    this.userId,
    this.canRestoreFromCache = true,
  });

  const AuthSession.signedOut()
    : isAuthenticated = false,
      userId = null,
      canRestoreFromCache = true;

  const AuthSession.signedOutAfterClear()
    : isAuthenticated = false,
      userId = null,
      canRestoreFromCache = false;

  final bool isAuthenticated;
  final String? userId;
  final bool canRestoreFromCache;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthSession &&
            other.isAuthenticated == isAuthenticated &&
            other.userId == userId &&
            other.canRestoreFromCache == canRestoreFromCache;
  }

  @override
  int get hashCode => Object.hash(isAuthenticated, userId, canRestoreFromCache);
}
