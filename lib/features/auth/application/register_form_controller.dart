import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterFormState {
  const RegisterFormState({this.email = '', this.agreedToPrivacyPolicy = true});

  final String email;
  final bool agreedToPrivacyPolicy;

  bool get canSendCode => email.trim().isNotEmpty && agreedToPrivacyPolicy;

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
}
