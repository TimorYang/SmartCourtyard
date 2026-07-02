import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'login_form_controller.dart';
import 'register_form_controller.dart';
import '../data/repositories/auth_session_repository_impl.dart';
import '../domain/entities/auth_session.dart';
import '../domain/repositories/auth_session_repository.dart';

final authSessionRepositoryProvider = Provider<AuthSessionRepository>((ref) {
  return const AuthSessionRepositoryImpl();
});

final authSessionProvider = Provider<AuthSession>((ref) {
  final repository = ref.watch(authSessionRepositoryProvider);
  return repository.readCurrentSession();
});

final loginFormControllerProvider =
    NotifierProvider.autoDispose<LoginFormController, LoginFormState>(() {
      return LoginFormController();
    });

final registerFormControllerProvider =
    NotifierProvider.autoDispose<RegisterFormController, RegisterFormState>(() {
      return RegisterFormController();
    });
