import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/validation/input_validators.dart';
import 'providers.dart';

class ForgotPasswordState {
  const ForgotPasswordState({
    this.email = '',
    this.isSendingCode = false,
    this.errorMessageKey,
    this.errorMessage,
  });

  final String email;
  final bool isSendingCode;
  final String? errorMessageKey;
  final String? errorMessage;

  String get trimmedEmail => email.trim();

  bool get hasEmailInput => trimmedEmail.isNotEmpty;

  bool get isEmailValid => InputValidators.isValidEmail(email);

  bool get canSendCode => hasEmailInput && !isSendingCode;

  ForgotPasswordState copyWith({
    String? email,
    bool? isSendingCode,
    String? errorMessageKey,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      isSendingCode: isSendingCode ?? this.isSendingCode,
      errorMessageKey: clearError
          ? null
          : errorMessageKey ?? this.errorMessageKey,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ForgotPasswordController extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() {
    return const ForgotPasswordState();
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value, clearError: true);
  }

  bool validateEmailForSubmit() {
    return state.isEmailValid;
  }

  Future<bool> sendCode() async {
    if (!validateEmailForSubmit() || state.isSendingCode) return false;
    state = state.copyWith(isSendingCode: true, clearError: true);
    try {
      await ref.read(sendPasswordResetEmailCodeUseCaseProvider)(
        state.trimmedEmail,
      );
      ref.read(passwordResetFlowStoreProvider).start(state.trimmedEmail);
      return true;
    } on AppError catch (error) {
      state = state.copyWith(
        errorMessageKey: error.messageKey,
        errorMessage: error.userMessage,
      );
      return false;
    } catch (_) {
      state = state.copyWith(errorMessageKey: 'auth.passwordReset.unavailable');
      return false;
    } finally {
      state = state.copyWith(isSendingCode: false);
    }
  }
}
