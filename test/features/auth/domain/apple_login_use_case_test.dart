import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';
import 'package:flinx/features/account/domain/repositories/account_repository.dart';
import 'package:flinx/features/auth/domain/entities/apple_identity_credential.dart';
import 'package:flinx/features/auth/domain/entities/apple_login_nonce.dart';
import 'package:flinx/features/auth/domain/entities/auth_login_result.dart';
import 'package:flinx/features/auth/domain/entities/login_device_context.dart';
import 'package:flinx/features/auth/domain/repositories/auth_login_repository.dart';
import 'package:flinx/features/auth/domain/services/apple_identity_provider.dart';
import 'package:flinx/features/auth/domain/services/login_device_context_provider.dart';
import 'package:flinx/features/auth/domain/use_cases/apple_login_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'gets a nonce, authorizes with its SHA-256, and persists the session',
    () async {
      final calls = <String>[];
      final identityProvider = _FakeAppleIdentityProvider(calls);
      final loginRepository = _FakeAuthLoginRepository(calls);
      final accountRepository = _FakeAccountRepository();
      final useCase = AppleLoginUseCase(
        identityProvider: identityProvider,
        loginRepository: loginRepository,
        accountRepository: accountRepository,
        deviceContextProvider: _FakeLoginDeviceContextProvider(calls),
        requestIdGenerator: () => 'apple-login-123',
      );

      final result = await useCase();

      expect(identityProvider.authorizeCalls, 1);
      expect(
        identityProvider.hashedNonce,
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(calls, ['device-context', 'nonce', 'authorize', 'login']);
      expect(loginRepository.nonceId, 'nonce-id');
      expect(loginRepository.identityToken, 'header.payload.signature');
      expect(loginRepository.authorizationCode, 'authorization-code');
      expect(loginRepository.givenName, 'Alice');
      expect(loginRepository.familyName, 'Smith');
      expect(loginRepository.deviceId, 'installation-id');
      expect(loginRepository.platform, 'IOS');
      expect(loginRepository.requestId, 'apple-login-123');
      expect(loginRepository.nonceRequestId, 'apple-login-123');
      expect(accountRepository.savedProfile, result.profile);
      expect(accountRepository.savedTokenSet, result.tokenSet);
    },
  );
}

class _FakeAppleIdentityProvider implements AppleIdentityProvider {
  _FakeAppleIdentityProvider(this.calls);

  final List<String> calls;
  int authorizeCalls = 0;
  String? hashedNonce;

  @override
  Future<AppleIdentityCredential> authorize({
    required String hashedNonce,
  }) async {
    calls.add('authorize');
    authorizeCalls += 1;
    this.hashedNonce = hashedNonce;
    return const AppleIdentityCredential(
      identityToken: 'header.payload.signature',
      authorizationCode: 'authorization-code',
      givenName: 'Alice',
      familyName: 'Smith',
    );
  }

  @override
  Future<bool> isAvailable() async => true;
}

class _FakeAuthLoginRepository implements AuthLoginRepository {
  _FakeAuthLoginRepository(this.calls);

  final List<String> calls;
  String? nonceRequestId;
  String? nonceId;
  String? identityToken;
  String? authorizationCode;
  String? givenName;
  String? familyName;
  String? deviceId;
  String? platform;
  String? requestId;

  @override
  Future<AppleLoginNonce> getAppleLoginNonce({
    required String requestId,
  }) async {
    calls.add('nonce');
    nonceRequestId = requestId;
    return const AppleLoginNonce(
      nonceId: 'nonce-id',
      nonce: 'abc',
      expiresIn: Duration(minutes: 5),
    );
  }

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
    calls.add('login');
    this.nonceId = nonceId;
    this.identityToken = identityToken;
    this.authorizationCode = authorizationCode;
    this.givenName = givenName;
    this.familyName = familyName;
    this.deviceId = deviceId;
    this.platform = platform;
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

class _FakeLoginDeviceContextProvider implements LoginDeviceContextProvider {
  const _FakeLoginDeviceContextProvider(this.calls);

  final List<String> calls;

  @override
  Future<LoginDeviceContext> read() async {
    calls.add('device-context');
    return const LoginDeviceContext(
      deviceId: 'installation-id',
      deviceModel: 'iPhone17,2',
      platform: 'IOS',
      appVersion: '1.0.0',
    );
  }
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
