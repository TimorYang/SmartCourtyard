import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/auth_session.dart';

class AuthSessionController extends Notifier<AuthSession> {
  @override
  AuthSession build() => const AuthSession.signedOut();

  void markAuthenticated() {
    state = const AuthSession(isAuthenticated: true);
  }

  void clear() {
    state = const AuthSession.signedOut();
  }
}
