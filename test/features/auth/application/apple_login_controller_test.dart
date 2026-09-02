import 'dart:async';

import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';
import 'package:flinx/features/account/domain/repositories/account_repository.dart';
import 'package:flinx/features/auth/application/apple_login_controller.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/apple_identity_credential.dart';
import 'package:flinx/features/auth/domain/entities/apple_login_nonce.dart';
import 'package:flinx/features/auth/domain/entities/auth_login_result.dart';
import 'package:flinx/features/auth/domain/entities/google_login_nonce.dart';
import 'package:flinx/features/auth/domain/entities/login_device_context.dart';
import 'package:flinx/features/auth/domain/repositories/auth_login_repository.dart';
import 'package:flinx/features/auth/domain/services/apple_identity_provider.dart';
import 'package:flinx/features/auth/domain/services/login_device_context_provider.dart';
import 'package:flinx/features/auth/domain/use_cases/apple_login_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not authorize before the agreements are accepted', () async {
    final identityProvider = _FakeAppleIdentityProvider();
    final container = _createContainer(identityProvider);

    final submission = await container
        .read(appleLoginControllerProvider.notifier)
        .submit(agreedToTerms: false);

    expect(submission.type, AppleLoginSubmissionType.agreementRequired);
    expect(identityProvider.authorizeCalls, 0);
  });

  test('returns a successful FLINX login and clears pending state', () async {
    final identityProvider = _FakeAppleIdentityProvider();
    final container = _createContainer(identityProvider);

    final submission = await container
        .read(appleLoginControllerProvider.notifier)
        .submit(agreedToTerms: true);

    expect(submission.type, AppleLoginSubmissionType.success);
    expect(submission.result?.profile.userId, '2');
    expect(container.read(appleLoginControllerProvider).isSubmitting, isFalse);
  });

  test('maps Apple cancellation without treating it as a failure', () async {
    final identityProvider = _FakeAppleIdentityProvider(
      error: const AppleIdentityException(AppleIdentityErrorCode.canceled),
    );
    final container = _createContainer(identityProvider);

    final submission = await container
        .read(appleLoginControllerProvider.notifier)
        .submit(agreedToTerms: true);

    expect(submission.type, AppleLoginSubmissionType.canceled);
    expect(container.read(appleLoginControllerProvider).isSubmitting, isFalse);
  });

  test('rejects duplicate submissions while Apple login is pending', () async {
    final blocker = Completer<void>();
    final identityProvider = _FakeAppleIdentityProvider(blocker: blocker);
    final container = _createContainer(identityProvider);
    final subscription = container.listen(
      appleLoginControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    final firstSubmission = container
        .read(appleLoginControllerProvider.notifier)
        .submit(agreedToTerms: true);
    await Future<void>.delayed(Duration.zero);

    final duplicateSubmission = await container
        .read(appleLoginControllerProvider.notifier)
        .submit(agreedToTerms: true);

    expect(duplicateSubmission.type, AppleLoginSubmissionType.busy);
    blocker.complete();
    expect((await firstSubmission).type, AppleLoginSubmissionType.success);
  });

  test('does not write state after the controller is disposed', () async {
    final blocker = Completer<void>();
    final identityProvider = _FakeAppleIdentityProvider(blocker: blocker);
    final container = _createContainer(identityProvider);
    final subscription = container.listen(
      appleLoginControllerProvider,
      (_, _) {},
    );

    final submission = container
        .read(appleLoginControllerProvider.notifier)
        .submit(agreedToTerms: true);
    await Future<void>.delayed(Duration.zero);
    subscription.close();
    await Future<void>.delayed(Duration.zero);

    blocker.complete();

    expect((await submission).type, AppleLoginSubmissionType.success);
  });
}

ProviderContainer _createContainer(
  _FakeAppleIdentityProvider identityProvider,
) {
  final useCase = AppleLoginUseCase(
    identityProvider: identityProvider,
    loginRepository: _FakeAuthLoginRepository(),
    accountRepository: _FakeAccountRepository(),
    deviceContextProvider: const _FakeLoginDeviceContextProvider(),
  );
  final container = ProviderContainer(
    overrides: [appleLoginUseCaseProvider.overrideWithValue(useCase)],
  );
  addTearDown(container.dispose);
  return container;
}

class _FakeAppleIdentityProvider implements AppleIdentityProvider {
  _FakeAppleIdentityProvider({this.error, this.blocker});

  final AppleIdentityException? error;
  final Completer<void>? blocker;
  int authorizeCalls = 0;

  @override
  Future<AppleIdentityCredential> authorize({
    required String hashedNonce,
  }) async {
    authorizeCalls += 1;
    await blocker?.future;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return const AppleIdentityCredential(
      identityToken: 'header.payload.signature',
      authorizationCode: 'authorization-code',
    );
  }

  @override
  Future<bool> isAvailable() async => true;
}

class _FakeAuthLoginRepository implements AuthLoginRepository {
  @override
  Future<AppleLoginNonce> getAppleLoginNonce({
    required String requestId,
  }) async => const AppleLoginNonce(
    nonceId: 'nonce-id',
    nonce: 'abc',
    expiresIn: Duration(minutes: 5),
  );

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
  }) async {
    return AuthLoginResult(
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
  }

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
  }) => throw UnimplementedError();

  @override
  Future<GoogleLoginNonce> getGoogleLoginNonce({required String requestId}) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
