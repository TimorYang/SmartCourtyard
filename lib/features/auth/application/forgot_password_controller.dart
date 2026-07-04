import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordState {
  const ForgotPasswordState({this.email = ''});

  final String email;

  bool get canSendCode => email.trim().isNotEmpty;

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
}
