import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import 'providers.dart';

class RegisterPasswordState {
  const RegisterPasswordState({
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

  RegisterPasswordState copyWith({
    String? password,
    String? confirmPassword,
    bool? isSubmitting,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return RegisterPasswordState(
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessageKey: clearError
          ? null
          : errorMessageKey ?? this.errorMessageKey,
    );
  }
}

class RegisterPasswordController extends Notifier<RegisterPasswordState> {
  static final _digitsOnlyPattern = RegExp(r'\D');

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
    final digits = value.replaceAll(_digitsOnlyPattern, '');
    return digits.length > 8 ? digits.substring(0, 8) : digits;
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
      state = state.copyWith(errorMessageKey: error.messageKey);
      return false;
    } catch (_) {
      state = state.copyWith(errorMessageKey: 'auth.registration.unavailable');
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
