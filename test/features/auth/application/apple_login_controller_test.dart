import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';
import 'package:flinx/features/account/domain/repositories/account_repository.dart';
import 'package:flinx/features/auth/application/apple_login_controller.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/apple_identity_credential.dart';
import 'package:flinx/features/auth/domain/entities/auth_login_result.dart';
import 'package:flinx/features/auth/domain/repositories/auth_login_repository.dart';
import 'package:flinx/features/auth/domain/services/apple_identity_provider.dart';
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
}

ProviderContainer _createContainer(
  _FakeAppleIdentityProvider identityProvider,
) {
  final useCase = AppleLoginUseCase(
    identityProvider: identityProvider,
    loginRepository: _FakeAuthLoginRepository(),
    accountRepository: _FakeAccountRepository(),
  );
  final container = ProviderContainer(
    overrides: [appleLoginUseCaseProvider.overrideWithValue(useCase)],
  );
  addTearDown(container.dispose);
  return container;
}

class _FakeAppleIdentityProvider implements AppleIdentityProvider {
  _FakeAppleIdentityProvider({this.error});

  final AppleIdentityException? error;
  int authorizeCalls = 0;

  @override
  Future<AppleIdentityCredential> authorize() async {
    authorizeCalls += 1;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return const AppleIdentityCredential(
      identityToken: 'header.payload.signature',
    );
  }

  @override
  Future<bool> isAvailable() async => true;
}

class _FakeAuthLoginRepository implements AuthLoginRepository {
  @override
  Future<AuthLoginResult> loginWithApple({
    required String identityToken,
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAccountRepository implements AccountRepository {
  @override
  Future<void> saveProfile(AccountProfile profile) async {}

  @override
  Future<void> saveTokenSet(AccountTokenSet tokenSet) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
