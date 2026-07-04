import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterPasswordState {
  const RegisterPasswordState({this.password = '', this.confirmPassword = ''});

  final String password;
  final String confirmPassword;

  bool get hasCompletePassword => password.length == 8;

  bool get hasCompleteConfirmation => confirmPassword.length == 8;

  bool get passwordsMatch =>
      hasCompletePassword &&
      hasCompleteConfirmation &&
      password == confirmPassword;

  bool get canSubmit => passwordsMatch;

  RegisterPasswordState copyWith({String? password, String? confirmPassword}) {
    return RegisterPasswordState(
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
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
    state = state.copyWith(password: _normalizedPassword(value));
  }

  void updateConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: _normalizedPassword(value));
  }

  static String _normalizedPassword(String value) {
    final digits = value.replaceAll(_digitsOnlyPattern, '');
    return digits.length > 8 ? digits.substring(0, 8) : digits;
  }
}
