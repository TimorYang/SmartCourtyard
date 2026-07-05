import 'dart:async';

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
  static const _resendCountdownSeconds = 59;
  static final _digitsOnlyPattern = RegExp(r'\D');

  Timer? _resendTimer;

  @override
  RegisterCodeState build() {
    ref.onDispose(_stopResendCountdown);
    _startResendCountdown();
    return const RegisterCodeState(
      resendSecondsRemaining: _resendCountdownSeconds,
    );
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

    state = state.copyWith(resendSecondsRemaining: _resendCountdownSeconds);
    _startResendCountdown();
  }

  void _startResendCountdown() {
    _stopResendCountdown();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.resendSecondsRemaining;
      if (remaining <= 1) {
        state = state.copyWith(resendSecondsRemaining: 0);
        _stopResendCountdown();
        return;
      }

      state = state.copyWith(resendSecondsRemaining: remaining - 1);
    });
  }

  void _stopResendCountdown() {
    _resendTimer?.cancel();
    _resendTimer = null;
  }
}
