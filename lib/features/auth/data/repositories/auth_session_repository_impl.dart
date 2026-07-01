import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_session_repository.dart';

class AuthSessionRepositoryImpl implements AuthSessionRepository {
  const AuthSessionRepositoryImpl({this.cachedUserId});

  final String? cachedUserId;

  @override
  AuthSession readCurrentSession() {
    final userId = cachedUserId?.trim();
    if (userId == null || userId.isEmpty) {
      return const AuthSession.signedOut();
    }

    return AuthSession(isAuthenticated: true, userId: userId);
  }
}
