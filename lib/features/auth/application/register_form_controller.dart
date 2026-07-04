import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/validation/input_validators.dart';

class RegisterFormState {
  const RegisterFormState({this.email = '', this.agreedToPrivacyPolicy = true});

  final String email;
  final bool agreedToPrivacyPolicy;

  String get trimmedEmail => email.trim();

  bool get hasEmailInput => trimmedEmail.isNotEmpty;

  bool get isEmailValid => InputValidators.isValidEmail(email);

  bool get canSendCode => hasEmailInput && agreedToPrivacyPolicy;

  RegisterFormState copyWith({String? email, bool? agreedToPrivacyPolicy}) {
    return RegisterFormState(
      email: email ?? this.email,
      agreedToPrivacyPolicy:
          agreedToPrivacyPolicy ?? this.agreedToPrivacyPolicy,
    );
  }
}

class RegisterFormController extends Notifier<RegisterFormState> {
  @override
  RegisterFormState build() {
    return const RegisterFormState();
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value);
  }

  void togglePrivacyAgreement() {
    state = state.copyWith(agreedToPrivacyPolicy: !state.agreedToPrivacyPolicy);
  }

  bool validateEmailForSubmit() {
    return state.isEmailValid;
  }
}
