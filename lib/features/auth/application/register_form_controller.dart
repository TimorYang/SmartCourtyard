import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/validation/input_validators.dart';
import 'providers.dart';

class RegisterFormState {
  const RegisterFormState({
    this.email = '',
    this.agreedToPrivacyPolicy = true,
    this.isSubmitting = false,
    this.errorMessageKey,
  });

  final String email;
  final bool agreedToPrivacyPolicy;
  final bool isSubmitting;
  final String? errorMessageKey;

  String get trimmedEmail => email.trim();

  bool get hasEmailInput => trimmedEmail.isNotEmpty;

  bool get isEmailValid => InputValidators.isValidEmail(email);

  bool get canSendCode =>
      hasEmailInput && agreedToPrivacyPolicy && !isSubmitting;

  RegisterFormState copyWith({
    String? email,
    bool? agreedToPrivacyPolicy,
    bool? isSubmitting,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return RegisterFormState(
      email: email ?? this.email,
      agreedToPrivacyPolicy:
          agreedToPrivacyPolicy ?? this.agreedToPrivacyPolicy,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessageKey: clearError
          ? null
          : errorMessageKey ?? this.errorMessageKey,
    );
  }
}

class RegisterFormController extends Notifier<RegisterFormState> {
  @override
  RegisterFormState build() {
    return const RegisterFormState();
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value, clearError: true);
  }

  void togglePrivacyAgreement() {
    state = state.copyWith(agreedToPrivacyPolicy: !state.agreedToPrivacyPolicy);
  }

  bool validateEmailForSubmit() {
    return state.isEmailValid;
  }

  Future<bool> sendCode() async {
    if (!validateEmailForSubmit() || state.isSubmitting) {
      if (kDebugMode) {
        debugPrint(
          '[FLINX][REGISTER] sendCode skipped: '
          'validEmail=${validateEmailForSubmit()} isSubmitting=${state.isSubmitting}',
        );
      }
      return false;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      if (kDebugMode) {
        debugPrint('[FLINX][REGISTER] Sending email verification code.');
      }
      await ref.read(sendRegistrationEmailCodeUseCaseProvider)(
        state.trimmedEmail,
      );
      ref.read(registrationFlowStoreProvider).start(state.trimmedEmail);
      return true;
    } on AppError catch (error) {
      state = state.copyWith(errorMessageKey: error.messageKey);
      return false;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[FLINX][REGISTER] Sending email code failed: $error');
      }
      state = state.copyWith(errorMessageKey: 'auth.registration.unavailable');
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
