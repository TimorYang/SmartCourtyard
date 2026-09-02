import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/auth_login_result.dart';
import '../domain/services/apple_identity_provider.dart';
import 'providers.dart';

class AppleLoginState {
  const AppleLoginState({this.isSubmitting = false});

  final bool isSubmitting;

  AppleLoginState copyWith({bool? isSubmitting}) {
    return AppleLoginState(isSubmitting: isSubmitting ?? this.isSubmitting);
  }
}

enum AppleLoginSubmissionType {
  success,
  agreementRequired,
  canceled,
  unavailable,
  failed,
  busy,
}

class AppleLoginSubmission {
  const AppleLoginSubmission._(this.type, [this.result, this.error]);

  const AppleLoginSubmission.success(AuthLoginResult result)
    : this._(AppleLoginSubmissionType.success, result);

  const AppleLoginSubmission.agreementRequired()
    : this._(AppleLoginSubmissionType.agreementRequired);

  const AppleLoginSubmission.canceled()
    : this._(AppleLoginSubmissionType.canceled);

  const AppleLoginSubmission.unavailable()
    : this._(AppleLoginSubmissionType.unavailable);

  const AppleLoginSubmission.failed([Object? error])
    : this._(AppleLoginSubmissionType.failed, null, error);

  const AppleLoginSubmission.busy() : this._(AppleLoginSubmissionType.busy);

  final AppleLoginSubmissionType type;
  final AuthLoginResult? result;
  final Object? error;
}

class AppleLoginController extends Notifier<AppleLoginState> {
  @override
  AppleLoginState build() => const AppleLoginState();

  Future<AppleLoginSubmission> submit({required bool agreedToTerms}) async {
    if (!agreedToTerms) {
      return const AppleLoginSubmission.agreementRequired();
    }
    if (state.isSubmitting) {
      return const AppleLoginSubmission.busy();
    }

    state = state.copyWith(isSubmitting: true);
    try {
      final result = await ref.read(appleLoginUseCaseProvider)();
      return AppleLoginSubmission.success(result);
    } on AppleIdentityException catch (error) {
      return switch (error.code) {
        AppleIdentityErrorCode.canceled =>
          const AppleLoginSubmission.canceled(),
        AppleIdentityErrorCode.unavailable =>
          const AppleLoginSubmission.unavailable(),
        AppleIdentityErrorCode.invalidCredential ||
        AppleIdentityErrorCode.failed => AppleLoginSubmission.failed(error),
      };
    } on Object catch (error) {
      return AppleLoginSubmission.failed(error);
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isSubmitting: false);
      }
    }
  }
}
