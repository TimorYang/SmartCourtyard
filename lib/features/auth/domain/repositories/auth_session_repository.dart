import '../entities/auth_session.dart';

abstract class AuthSessionRepository {
  AuthSession readCurrentSession();
}
