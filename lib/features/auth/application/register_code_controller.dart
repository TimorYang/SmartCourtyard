import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterCodeState {
  const RegisterCodeState({this.code = '', this.resendSecondsRemaining = 59});

  final String code;
  final int resendSecondsRemaining;

  bool get isComplete => code.length == 6;

  bool get canResend => resendSecondsRemaining == 0;

  RegisterCodeState copyWith({String? code, int? resendSecondsRemaining}) {
    return RegisterCodeState(
      code: code ?? this.code,
      resendSecondsRemaining:
          resendSecondsRemaining ?? this.resendSecondsRemaining,
    );
  }
}

class RegisterCodeController extends Notifier<RegisterCodeState> {
  static final _digitsOnlyPattern = RegExp(r'\D');

  @override
  RegisterCodeState build() {
    return const RegisterCodeState();
  }

  void updateCode(String value) {
    final digits = value.replaceAll(_digitsOnlyPattern, '');
    state = state.copyWith(
      code: digits.length > 6 ? digits.substring(0, 6) : digits,
    );
  }

  void resetResendCountdown() {
    if (!state.canResend) {
      return;
    }

    state = state.copyWith(resendSecondsRemaining: 59);
  }
}
