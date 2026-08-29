import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../domain/entities/password_policy.dart';
import 'providers.dart';

class RegisterPasswordState {
  const RegisterPasswordState({
    this.password = '',
    this.confirmPassword = '',
    this.isSubmitting = false,
    this.errorMessageKey,
    this.errorMessage,
  });

  final String password;
  final String confirmPassword;
  final bool isSubmitting;
  final String? errorMessageKey;
  final String? errorMessage;

  bool get hasValidPassword => PasswordPolicy.isValid(password);

  bool get hasValidConfirmation => PasswordPolicy.isValid(confirmPassword);

  bool get passwordsMatch =>
      hasValidPassword && hasValidConfirmation && password == confirmPassword;

  bool get canSubmit => passwordsMatch && !isSubmitting;

  RegisterPasswordState copyWith({
    String? password,
    String? confirmPassword,
    bool? isSubmitting,
    String? errorMessageKey,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RegisterPasswordState(
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessageKey: clearError
          ? null
          : errorMessageKey ?? this.errorMessageKey,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class RegisterPasswordController extends Notifier<RegisterPasswordState> {
  @override
  RegisterPasswordState build() {
    return const RegisterPasswordState();
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
    return value.length > PasswordPolicy.maxLength
        ? value.substring(0, PasswordPolicy.maxLength)
        : value;
  }

  Future<bool> submit() async {
    if (!state.canSubmit) return false;
    final token = ref.read(registrationFlowStoreProvider).registrationToken;
    if (token == null) {
      state = state.copyWith(
        errorMessageKey: 'auth.registration.restartRequired',
      );
      return false;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final deviceContext = await ref.read(
        registrationDeviceContextProvider.future,
      );
      await ref.read(completeRegistrationUseCaseProvider)(
        registrationToken: token,
        password: state.password,
        confirmPassword: state.confirmPassword,
        deviceContext: deviceContext,
      );
      ref.read(registrationFlowStoreProvider).clear();
      return true;
    } on AppError catch (error) {
      state = state.copyWith(
        errorMessageKey: error.messageKey,
        errorMessage: error.userMessage,
      );
      return false;
    } catch (_) {
      state = state.copyWith(errorMessageKey: 'auth.registration.unavailable');
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
