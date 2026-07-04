import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'forgot_password_code_controller.dart';
import 'forgot_password_controller.dart';
import 'forgot_password_reset_controller.dart';
import 'login_form_controller.dart';
import 'register_code_controller.dart';
import 'register_form_controller.dart';
import 'register_password_controller.dart';
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

final forgotPasswordControllerProvider =
    NotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>(
      () {
        return ForgotPasswordController();
      },
    );

final forgotPasswordCodeControllerProvider =
    NotifierProvider.autoDispose<
      ForgotPasswordCodeController,
      ForgotPasswordCodeState
    >(() {
      return ForgotPasswordCodeController();
    });

final forgotPasswordResetControllerProvider =
    NotifierProvider.autoDispose<
      ForgotPasswordResetController,
      ForgotPasswordResetState
    >(() {
      return ForgotPasswordResetController();
    });

final registerFormControllerProvider =
    NotifierProvider.autoDispose<RegisterFormController, RegisterFormState>(() {
      return RegisterFormController();
    });

final registerCodeControllerProvider =
    NotifierProvider.autoDispose<RegisterCodeController, RegisterCodeState>(() {
      return RegisterCodeController();
    });

final registerPasswordControllerProvider =
    NotifierProvider.autoDispose<
      RegisterPasswordController,
      RegisterPasswordState
    >(() {
      return RegisterPasswordController();
    });
