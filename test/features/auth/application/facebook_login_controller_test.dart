import 'dart:async';

import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';
import 'package:flinx/features/account/domain/repositories/account_repository.dart';
import 'package:flinx/features/auth/application/facebook_login_controller.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/auth_login_result.dart';
import 'package:flinx/features/auth/domain/entities/facebook_identity_credential.dart';
import 'package:flinx/features/auth/domain/entities/facebook_login_nonce.dart';
import 'package:flinx/features/auth/domain/entities/login_device_context.dart';
import 'package:flinx/features/auth/domain/repositories/auth_login_repository.dart';
import 'package:flinx/features/auth/domain/services/facebook_identity_provider.dart';
import 'package:flinx/features/auth/domain/services/login_device_context_provider.dart';
import 'package:flinx/features/auth/domain/use_cases/facebook_login_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not authorize before the agreements are accepted', () async {
    final identityProvider = _FakeFacebookIdentityProvider();
    final container = _createContainer(identityProvider);

    final submission = await container
        .read(facebookLoginControllerProvider.notifier)
        .submit(agreedToTerms: false);

    expect(submission.type, FacebookLoginSubmissionType.agreementRequired);
    expect(identityProvider.authorizeCalls, 0);
  });

  test('returns a successful login and clears pending state', () async {
    final identityProvider = _FakeFacebookIdentityProvider();
    final container = _createContainer(identityProvider);

    final submission = await container
        .read(facebookLoginControllerProvider.notifier)
        .submit(agreedToTerms: true);

    expect(submission.type, FacebookLoginSubmissionType.success);
    expect(submission.result?.profile.userId, '2');
    expect(
      container.read(facebookLoginControllerProvider).isSubmitting,
      isFalse,
    );
  });

  test('maps Facebook cancellation without treating it as a failure', () async {
    final identityProvider = _FakeFacebookIdentityProvider(
      error: const FacebookIdentityException(
        FacebookIdentityErrorCode.canceled,
      ),
    );
    final container = _createContainer(identityProvider);

    final submission = await container
        .read(facebookLoginControllerProvider.notifier)
        .submit(agreedToTerms: true);

    expect(submission.type, FacebookLoginSubmissionType.canceled);
    expect(
      container.read(facebookLoginControllerProvider).isSubmitting,
      isFalse,
    );
  });

  test('maps a missing Facebook configuration to unavailable', () async {
    final identityProvider = _FakeFacebookIdentityProvider(available: false);
    final container = _createContainer(identityProvider);

    final submission = await container
        .read(facebookLoginControllerProvider.notifier)
        .submit(agreedToTerms: true);

    expect(submission.type, FacebookLoginSubmissionType.unavailable);
    expect(identityProvider.authorizeCalls, 0);
  });

  test(
    'rejects duplicate submissions while Facebook login is pending',
    () async {
      final blocker = Completer<void>();
      final identityProvider = _FakeFacebookIdentityProvider(blocker: blocker);
      final container = _createContainer(identityProvider);
      final subscription = container.listen(
        facebookLoginControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      final firstSubmission = container
          .read(facebookLoginControllerProvider.notifier)
          .submit(agreedToTerms: true);
      await Future<void>.delayed(Duration.zero);

      final duplicateSubmission = await container
          .read(facebookLoginControllerProvider.notifier)
          .submit(agreedToTerms: true);

      expect(duplicateSubmission.type, FacebookLoginSubmissionType.busy);
      blocker.complete();
      expect((await firstSubmission).type, FacebookLoginSubmissionType.success);
    },
  );
}

ProviderContainer _createContainer(
  _FakeFacebookIdentityProvider identityProvider,
) {
  final useCase = FacebookLoginUseCase(
    identityProvider: identityProvider,
    loginRepository: _FakeAuthLoginRepository(),
    accountRepository: _FakeAccountRepository(),
    deviceContextProvider: const _FakeLoginDeviceContextProvider(),
  );
  final container = ProviderContainer(
    overrides: [facebookLoginUseCaseProvider.overrideWithValue(useCase)],
  );
  addTearDown(container.dispose);
  return container;
}

class _FakeFacebookIdentityProvider implements FacebookIdentityProvider {
  _FakeFacebookIdentityProvider({
    this.error,
    this.blocker,
    this.available = true,
  });

  final FacebookIdentityException? error;
  final Completer<void>? blocker;
  final bool available;
  int authorizeCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<FacebookIdentityCredential> authorize({
    required FacebookLoginPlatform platform,
    String? nonce,
  }) async {
    authorizeCalls += 1;
    await blocker?.future;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return FacebookIdentityCredential(
      kind: platform == FacebookLoginPlatform.ios
          ? FacebookTokenKind.authenticationToken
          : FacebookTokenKind.accessToken,
      tokenString: 'facebook-token',
    );
  }
}

class _FakeAuthLoginRepository implements AuthLoginRepository {
  @override
  Future<FacebookLoginNonce> getFacebookLoginNonce({
    required String requestId,
  }) async => const FacebookLoginNonce(
    nonceId: 'facebook-nonce-id',
    nonce: 'facebook-raw-nonce',
    expiresIn: Duration(minutes: 5),
  );

  @override
  Future<AuthLoginResult> loginWithFacebook({
    required FacebookIdentityCredential credential,
    required String? nonceId,
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
