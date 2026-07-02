import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginFormState {
  const LoginFormState({
    this.account = '',
    this.password = '',
    this.agreedToTerms = false,
  });

  final String account;
  final String password;
  final bool agreedToTerms;

  bool get canSubmit =>
      account.trim().isNotEmpty && password.isNotEmpty && agreedToTerms;

  LoginFormState copyWith({
    String? account,
    String? password,
    bool? agreedToTerms,
  }) {
    return LoginFormState(
      account: account ?? this.account,
      password: password ?? this.password,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
    );
  }
}

class LoginFormController extends Notifier<LoginFormState> {
  @override
  LoginFormState build() {
    return const LoginFormState();
  }

  void updateAccount(String value) {
    state = state.copyWith(account: value);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value);
  }

  void toggleAgreement() {
    state = state.copyWith(agreedToTerms: !state.agreedToTerms);
  }
}
