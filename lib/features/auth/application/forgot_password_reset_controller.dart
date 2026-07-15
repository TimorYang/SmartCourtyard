import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import 'providers.dart';

class ForgotPasswordResetState {
  const ForgotPasswordResetState({
    this.password = '',
    this.confirmPassword = '',
    this.isSubmitting = false,
    this.errorMessageKey,
  });

  final String password;
  final String confirmPassword;
  final bool isSubmitting;
  final String? errorMessageKey;

  bool get hasCompletePassword => password.length == 8;

  bool get hasCompleteConfirmation => confirmPassword.length == 8;

  bool get passwordsMatch =>
      hasCompletePassword &&
      hasCompleteConfirmation &&
      password == confirmPassword;

  bool get canSubmit => passwordsMatch && !isSubmitting;

  ForgotPasswordResetState copyWith({
    String? password,
    String? confirmPassword,
    bool? isSubmitting,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return ForgotPasswordResetState(
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessageKey: clearError
          ? null
          : errorMessageKey ?? this.errorMessageKey,
    );
  }
}

class ForgotPasswordResetController extends Notifier<ForgotPasswordResetState> {
  static final _digitsOnlyPattern = RegExp(r'\D');

  @override
  ForgotPasswordResetState build() {
    return const ForgotPasswordResetState();
  }

  void updatePassword(String value) {
    state = state.copyWith(
      password: _normalizedPassword(value),
      clearError: true,
    );
  }

  void updateConfirmPassword(String value) {
    state = state.copyWith(
      confirmPassword: _normalizedPassword(value),
      clearError: true,
    );
  }

  static String _normalizedPassword(String value) {
    final digits = value.replaceAll(_digitsOnlyPattern, '');
    return digits.length > 8 ? digits.substring(0, 8) : digits;
  }

  Future<bool> submit() async {
    if (!state.canSubmit) return false;
    final passwordResetToken = ref
        .read(passwordResetFlowStoreProvider)
        .passwordResetToken;
    if (passwordResetToken == null) {
      state = state.copyWith(
        errorMessageKey: 'auth.passwordReset.restartRequired',
      );
      return false;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await ref.read(completePasswordResetUseCaseProvider)(
        passwordResetToken: passwordResetToken,
        newPassword: state.password,
        confirmPassword: state.confirmPassword,
      );
      ref.read(passwordResetFlowStoreProvider).clear();
      return true;
    } on AppError catch (error) {
      state = state.copyWith(errorMessageKey: error.messageKey);
      return false;
    } catch (_) {
      state = state.copyWith(errorMessageKey: 'auth.passwordReset.unavailable');
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
