class AuthSession {
  const AuthSession({required this.isAuthenticated, this.userId});

  const AuthSession.signedOut() : isAuthenticated = false, userId = null;

  final bool isAuthenticated;
  final String? userId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthSession &&
            other.isAuthenticated == isAuthenticated &&
            other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(isAuthenticated, userId);
}
