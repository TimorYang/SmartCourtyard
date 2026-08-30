import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/auth_login_result.dart';
import '../domain/services/facebook_identity_provider.dart';
import 'providers.dart';

class FacebookLoginState {
  const FacebookLoginState({this.isSubmitting = false});

  final bool isSubmitting;

  FacebookLoginState copyWith({bool? isSubmitting}) {
    return FacebookLoginState(isSubmitting: isSubmitting ?? this.isSubmitting);
  }
}

enum FacebookLoginSubmissionType {
  success,
  agreementRequired,
  canceled,
  unavailable,
  failed,
  busy,
}

class FacebookLoginSubmission {
  const FacebookLoginSubmission._(this.type, [this.result]);

  const FacebookLoginSubmission.success(AuthLoginResult result)
    : this._(FacebookLoginSubmissionType.success, result);

  const FacebookLoginSubmission.agreementRequired()
    : this._(FacebookLoginSubmissionType.agreementRequired);

  const FacebookLoginSubmission.canceled()
    : this._(FacebookLoginSubmissionType.canceled);

  const FacebookLoginSubmission.unavailable()
    : this._(FacebookLoginSubmissionType.unavailable);

  const FacebookLoginSubmission.failed()
    : this._(FacebookLoginSubmissionType.failed);

  const FacebookLoginSubmission.busy()
    : this._(FacebookLoginSubmissionType.busy);

  final FacebookLoginSubmissionType type;
  final AuthLoginResult? result;
}

class FacebookLoginController extends Notifier<FacebookLoginState> {
  @override
  FacebookLoginState build() => const FacebookLoginState();

  Future<FacebookLoginSubmission> submit({required bool agreedToTerms}) async {
    if (!agreedToTerms) {
      return const FacebookLoginSubmission.agreementRequired();
    }
    if (state.isSubmitting) {
      return const FacebookLoginSubmission.busy();
    }

    state = state.copyWith(isSubmitting: true);
    try {
      final result = await ref.read(facebookLoginUseCaseProvider)();
      return FacebookLoginSubmission.success(result);
    } on FacebookIdentityException catch (error) {
      return switch (error.code) {
        FacebookIdentityErrorCode.canceled =>
          const FacebookLoginSubmission.canceled(),
        FacebookIdentityErrorCode.unavailable =>
          const FacebookLoginSubmission.unavailable(),
        FacebookIdentityErrorCode.invalidCredential ||
        FacebookIdentityErrorCode.failed =>
          const FacebookLoginSubmission.failed(),
      };
    } on Object {
      return const FacebookLoginSubmission.failed();
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
