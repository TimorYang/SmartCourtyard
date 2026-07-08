import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'forgot_password_code_controller.dart';
import 'forgot_password_controller.dart';
import 'forgot_password_reset_controller.dart';
import 'login_form_controller.dart';
import 'register_code_controller.dart';
import 'register_form_controller.dart';
import 'register_password_controller.dart';
import 'simulated_login_use_case.dart';
import '../../account/application/providers.dart';
import '../domain/entities/auth_session.dart';

final authSessionProvider = FutureProvider<AuthSession>((ref) async {
  final accountRepository = ref.watch(accountRepositoryProvider);
  final profile = await accountRepository.readCachedProfile();
  final tokenSet = await accountRepository.readTokenSet();
  if (profile == null || tokenSet == null) {
    return const AuthSession.signedOut();
  }

  if (profile.userId.isEmpty || !tokenSet.isUsableAt(DateTime.now())) {
    return const AuthSession.signedOut();
  }

  return AuthSession(isAuthenticated: true, userId: profile.userId);
});

final simulatedLoginUseCaseProvider = Provider<SimulatedLoginUseCase>((ref) {
  return SimulatedLoginUseCase(
    accountRepository: ref.watch(accountRepositoryProvider),
  );
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
