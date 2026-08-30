import 'dart:async';

import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';
import 'package:flinx/features/account/domain/repositories/account_repository.dart';
import 'package:flinx/features/auth/application/google_login_controller.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/apple_login_nonce.dart';
import 'package:flinx/features/auth/domain/entities/auth_login_result.dart';
import 'package:flinx/features/auth/domain/entities/google_identity_credential.dart';
import 'package:flinx/features/auth/domain/entities/google_login_nonce.dart';
import 'package:flinx/features/auth/domain/entities/login_device_context.dart';
import 'package:flinx/features/auth/domain/repositories/auth_login_repository.dart';
import 'package:flinx/features/auth/domain/services/google_identity_provider.dart';
import 'package:flinx/features/auth/domain/services/login_device_context_provider.dart';
import 'package:flinx/features/auth/domain/use_cases/google_login_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not authorize before the agreements are accepted', () async {
    final identityProvider = _FakeGoogleIdentityProvider();
    final container = _createContainer(identityProvider);

    final submission = await container
        .read(googleLoginControllerProvider.notifier)
        .submit(agreedToTerms: false);

    expect(submission.type, GoogleLoginSubmissionType.agreementRequired);
    expect(identityProvider.authorizeCalls, 0);
  });

  test('returns a successful login and clears pending state', () async {
    final identityProvider = _FakeGoogleIdentityProvider();
    final container = _createContainer(identityProvider);

    final submission = await container
        .read(googleLoginControllerProvider.notifier)
        .submit(agreedToTerms: true);

    expect(submission.type, GoogleLoginSubmissionType.success);
    expect(submission.result?.profile.userId, '2');
    expect(container.read(googleLoginControllerProvider).isSubmitting, isFalse);
  });

  test('maps Google cancellation without treating it as a failure', () async {
    final identityProvider = _FakeGoogleIdentityProvider(
      error: const GoogleIdentityException(GoogleIdentityErrorCode.canceled),
    );
    final container = _createContainer(identityProvider);

    final submission = await container
        .read(googleLoginControllerProvider.notifier)
        .submit(agreedToTerms: true);

    expect(submission.type, GoogleLoginSubmissionType.canceled);
    expect(container.read(googleLoginControllerProvider).isSubmitting, isFalse);
  });

  test('rejects duplicate submissions while Google login is pending', () async {
    final blocker = Completer<void>();
    final identityProvider = _FakeGoogleIdentityProvider(blocker: blocker);
    final container = _createContainer(identityProvider);
    final subscription = container.listen(
      googleLoginControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    final firstSubmission = container
        .read(googleLoginControllerProvider.notifier)
        .submit(agreedToTerms: true);
    await Future<void>.delayed(Duration.zero);

    final duplicateSubmission = await container
        .read(googleLoginControllerProvider.notifier)
        .submit(agreedToTerms: true);

    expect(duplicateSubmission.type, GoogleLoginSubmissionType.busy);
    blocker.complete();
    expect((await firstSubmission).type, GoogleLoginSubmissionType.success);
  });
}

ProviderContainer _createContainer(
  _FakeGoogleIdentityProvider identityProvider,
) {
  final useCase = GoogleLoginUseCase(
    identityProvider: identityProvider,
    loginRepository: _FakeAuthLoginRepository(),
    accountRepository: _FakeAccountRepository(),
    deviceContextProvider: const _FakeLoginDeviceContextProvider(),
  );
  final container = ProviderContainer(
    overrides: [googleLoginUseCaseProvider.overrideWithValue(useCase)],
  );
  addTearDown(container.dispose);
  return container;
}

class _FakeGoogleIdentityProvider implements GoogleIdentityProvider {
  _FakeGoogleIdentityProvider({this.error, this.blocker});

  final GoogleIdentityException? error;
  final Completer<void>? blocker;
  int authorizeCalls = 0;

  @override
  Future<GoogleIdentityCredential> authorize({required String nonce}) async {
    authorizeCalls += 1;
    await blocker?.future;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return const GoogleIdentityCredential(
      idToken: 'id-token',
      authorizationCode: 'authorization-code',
    );
  }

  @override
  Future<bool> isAvailable() async => true;
}

class _FakeAuthLoginRepository implements AuthLoginRepository {
  @override
  Future<AuthLoginResult> login({
    required String email,
    required String passwordCiphertext,
    required String keyId,
    required String nonce,
    required String deviceId,
    required String deviceModel,
    required String platform,
    required String appVersion,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<AuthLoginResult> loginWithApple({
    required String nonceId,
    required String identityToken,
    required String authorizationCode,
    required String? givenName,
    required String? familyName,
    required String deviceId,
    required String deviceModel,
    required String platform,
    required String appVersion,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<AppleLoginNonce> getAppleLoginNonce({required String requestId}) =>
      throw UnimplementedError();

  @override
  Future<AuthLoginResult> loginWithGoogle({
    required String nonceId,
    required String idToken,
    required String authorizationCode,
    required String deviceId,
    required String deviceModel,
    required String platform,
    required String appVersion,
    required String requestId,
  }) async => AuthLoginResult(
    tokenSet: const AccountTokenSet(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    ),
    profile: AccountProfile(
      userId: '2',
      email: 'alice@example.com',
      nickname: 'Alice',
    ),
  );

  @override
  Future<GoogleLoginNonce> getGoogleLoginNonce({required String requestId}) =>
      Future.value(
        const GoogleLoginNonce(
          nonceId: 'nonce-id',
          nonce: 'raw-nonce',
          expiresIn: Duration(minutes: 5),
        ),
      );
}

class _FakeLoginDeviceContextProvider implements LoginDeviceContextProvider {
  const _FakeLoginDeviceContextProvider();

  @override
  Future<LoginDeviceContext> read() async => const LoginDeviceContext(
    deviceId: 'installation-id',
    deviceModel: 'iPhone17,2',
    platform: 'IOS',
    appVersion: '1.0.0',
  );
}

class _FakeAccountRepository implements AccountRepository {
  @override
  Future<void> saveProfile(AccountProfile profile) async {}

  @override
  Future<void> saveTokenSet(AccountTokenSet tokenSet) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
