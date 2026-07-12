import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import 'providers.dart';

class RegisterCodeState {
  const RegisterCodeState({
    this.code = '',
    this.resendSecondsRemaining = 59,
    this.isVerifying = false,
    this.isResending = false,
    this.errorMessageKey,
  });

  final String code;
  final int resendSecondsRemaining;
  final bool isVerifying;
  final bool isResending;
  final String? errorMessageKey;

  bool get isComplete => code.length == 6;

  bool get canResend => resendSecondsRemaining == 0;

  RegisterCodeState copyWith({
    String? code,
    int? resendSecondsRemaining,
    bool? isVerifying,
    bool? isResending,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return RegisterCodeState(
      code: code ?? this.code,
      resendSecondsRemaining:
          resendSecondsRemaining ?? this.resendSecondsRemaining,
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      errorMessageKey: clearError
          ? null
          : errorMessageKey ?? this.errorMessageKey,
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
      clearError: true,
    );
  }

  void resetResendCountdown() {
    if (!state.canResend) {
      return;
    }

    state = state.copyWith(resendSecondsRemaining: _resendCountdownSeconds);
    _startResendCountdown();
  }

  Future<bool> verifyCode() async {
    if (!state.isComplete || state.isVerifying) return false;
    final email = ref.read(registrationFlowStoreProvider).email;
    if (email == null || email.isEmpty) {
      state = state.copyWith(
        errorMessageKey: 'auth.registration.restartRequired',
      );
      return false;
    }
    state = state.copyWith(isVerifying: true, clearError: true);
    try {
      final verification = await ref.read(
        verifyRegistrationEmailCodeUseCaseProvider,
      )(email: email, code: state.code);
      ref
          .read(registrationFlowStoreProvider)
          .setVerification(
            token: verification.registrationToken,
            expiresIn: verification.expiresIn,
          );
      return true;
    } on AppError catch (error) {
      state = state.copyWith(errorMessageKey: error.messageKey);
      return false;
    } catch (_) {
      state = state.copyWith(errorMessageKey: 'auth.registration.unavailable');
      return false;
    } finally {
      state = state.copyWith(isVerifying: false);
    }
  }

  Future<bool> resendCode() async {
    if (!state.canResend || state.isResending) return false;
    final email = ref.read(registrationFlowStoreProvider).email;
    if (email == null || email.isEmpty) {
      state = state.copyWith(
        errorMessageKey: 'auth.registration.restartRequired',
      );
      return false;
    }
    state = state.copyWith(isResending: true, clearError: true);
    try {
      await ref.read(sendRegistrationEmailCodeUseCaseProvider)(email);
      resetResendCountdown();
      return true;
    } on AppError catch (error) {
      state = state.copyWith(errorMessageKey: error.messageKey);
      return false;
    } catch (_) {
      state = state.copyWith(errorMessageKey: 'auth.registration.unavailable');
      return false;
    } finally {
      state = state.copyWith(isResending: false);
    }
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
