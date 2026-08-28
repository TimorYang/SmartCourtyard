import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/validation/input_validators.dart';

class LoginFormState {
  const LoginFormState({
    this.account = defaultLoginAccount,
    this.password = defaultLoginPassword,
    this.agreedToTerms = false,
  });

  final String account;
  final String password;
  final bool agreedToTerms;

  String get trimmedEmail => account.trim();

  bool get hasAccountInput => trimmedEmail.isNotEmpty;

  bool get isAccountEmailValid => InputValidators.isValidEmail(account);

  bool get canSubmit => hasAccountInput && password.isNotEmpty && agreedToTerms;

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

const defaultLoginAccount = '19901462575@163.com';
const defaultLoginPassword = '123456';

// const defaultLoginAccount = '1067648090@qq.com';
// const defaultLoginPassword = '123456';

// const defaultLoginAccount = '346054814@qq.com';
// const defaultLoginPassword = 'qaz1234WSX';

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

  bool validateEmailForSubmit() {
    return state.isAccountEmailValid;
  }
}
