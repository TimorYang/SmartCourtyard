class AuthSession {
  const AuthSession({required this.isAuthenticated, this.userId});

  const AuthSession.signedOut() : isAuthenticated = false, userId = null;

  final bool isAuthenticated;
  final String? userId;
}
