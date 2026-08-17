import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';
import 'package:flinx/features/account/domain/repositories/account_repository.dart';
import 'package:flinx/features/auth/domain/entities/apple_identity_credential.dart';
import 'package:flinx/features/auth/domain/entities/auth_login_result.dart';
import 'package:flinx/features/auth/domain/repositories/auth_login_repository.dart';
import 'package:flinx/features/auth/domain/services/apple_identity_provider.dart';
import 'package:flinx/features/auth/domain/use_cases/apple_login_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'exchanges the Apple identity token and persists the FLINX session',
    () async {
      final identityProvider = _FakeAppleIdentityProvider();
      final loginRepository = _FakeAuthLoginRepository();
      final accountRepository = _FakeAccountRepository();
      final useCase = AppleLoginUseCase(
        identityProvider: identityProvider,
        loginRepository: loginRepository,
        accountRepository: accountRepository,
        requestIdGenerator: () => 'apple-login-123',
      );

      final result = await useCase();

      expect(identityProvider.authorizeCalls, 1);
      expect(loginRepository.identityToken, 'header.payload.signature');
      expect(loginRepository.requestId, 'apple-login-123');
      expect(accountRepository.savedProfile, result.profile);
      expect(accountRepository.savedTokenSet, result.tokenSet);
    },
  );
}

class _FakeAppleIdentityProvider implements AppleIdentityProvider {
  int authorizeCalls = 0;

  @override
  Future<AppleIdentityCredential> authorize() async {
    authorizeCalls += 1;
    return const AppleIdentityCredential(
      identityToken: 'header.payload.signature',
    );
  }

  @override
  Future<bool> isAvailable() async => true;
}

class _FakeAuthLoginRepository implements AuthLoginRepository {
  String? identityToken;
  String? requestId;

  @override
  Future<AuthLoginResult> loginWithApple({
    required String identityToken,
    required String requestId,
  }) async {
    this.identityToken = identityToken;
    this.requestId = requestId;
    return AuthLoginResult(
      tokenSet: const AccountTokenSet(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
      profile: AccountProfile(
        userId: '2',
        email: 'alice@example.com',
        nickname: 'Alice',
        country: 'NL',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAccountRepository implements AccountRepository {
  AccountProfile? savedProfile;
  AccountTokenSet? savedTokenSet;

  @override
  Future<void> saveProfile(AccountProfile profile) async {
    savedProfile = profile;
  }

  @override
  Future<void> saveTokenSet(AccountTokenSet tokenSet) async {
    savedTokenSet = tokenSet;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
