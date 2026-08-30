import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/auth_login_result.dart';
import '../domain/services/google_identity_provider.dart';
import 'providers.dart';

class GoogleLoginState {
  const GoogleLoginState({this.isSubmitting = false});

  final bool isSubmitting;

  GoogleLoginState copyWith({bool? isSubmitting}) {
    return GoogleLoginState(isSubmitting: isSubmitting ?? this.isSubmitting);
  }
}

enum GoogleLoginSubmissionType {
  success,
  agreementRequired,
  canceled,
  unavailable,
  failed,
  busy,
}

class GoogleLoginSubmission {
  const GoogleLoginSubmission._(this.type, [this.result]);

  const GoogleLoginSubmission.success(AuthLoginResult result)
    : this._(GoogleLoginSubmissionType.success, result);

  const GoogleLoginSubmission.agreementRequired()
    : this._(GoogleLoginSubmissionType.agreementRequired);

  const GoogleLoginSubmission.canceled()
    : this._(GoogleLoginSubmissionType.canceled);

  const GoogleLoginSubmission.unavailable()
    : this._(GoogleLoginSubmissionType.unavailable);

  const GoogleLoginSubmission.failed()
    : this._(GoogleLoginSubmissionType.failed);

  const GoogleLoginSubmission.busy() : this._(GoogleLoginSubmissionType.busy);

  final GoogleLoginSubmissionType type;
  final AuthLoginResult? result;
}

class GoogleLoginController extends Notifier<GoogleLoginState> {
  @override
  GoogleLoginState build() => const GoogleLoginState();

  Future<GoogleLoginSubmission> submit({required bool agreedToTerms}) async {
    if (!agreedToTerms) {
      return const GoogleLoginSubmission.agreementRequired();
    }
    if (state.isSubmitting) {
      return const GoogleLoginSubmission.busy();
    }

    state = state.copyWith(isSubmitting: true);
    try {
      final result = await ref.read(googleLoginUseCaseProvider)();
      return GoogleLoginSubmission.success(result);
    } on GoogleIdentityException catch (error) {
      return switch (error.code) {
        GoogleIdentityErrorCode.canceled =>
          const GoogleLoginSubmission.canceled(),
        GoogleIdentityErrorCode.unavailable =>
          const GoogleLoginSubmission.unavailable(),
        GoogleIdentityErrorCode.invalidCredential ||
        GoogleIdentityErrorCode.failed => const GoogleLoginSubmission.failed(),
      };
    } on Object {
      return const GoogleLoginSubmission.failed();
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
