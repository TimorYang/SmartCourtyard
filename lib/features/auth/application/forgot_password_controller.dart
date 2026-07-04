import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/validation/input_validators.dart';

class ForgotPasswordState {
  const ForgotPasswordState({this.email = ''});

  final String email;

  String get trimmedEmail => email.trim();

  bool get hasEmailInput => trimmedEmail.isNotEmpty;

  bool get isEmailValid => InputValidators.isValidEmail(email);

  bool get canSendCode => hasEmailInput;

  ForgotPasswordState copyWith({String? email}) {
    return ForgotPasswordState(email: email ?? this.email);
  }
}

class ForgotPasswordController extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() {
    return const ForgotPasswordState();
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value);
  }

  bool validateEmailForSubmit() {
    return state.isEmailValid;
  }
}
