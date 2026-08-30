import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';
import 'package:flinx/features/account/domain/repositories/account_repository.dart';
import 'package:flinx/features/auth/domain/entities/auth_login_result.dart';
import 'package:flinx/features/auth/domain/entities/facebook_identity_credential.dart';
import 'package:flinx/features/auth/domain/entities/facebook_login_nonce.dart';
import 'package:flinx/features/auth/domain/entities/google_identity_credential.dart';
import 'package:flinx/features/auth/domain/entities/google_login_nonce.dart';
import 'package:flinx/features/auth/domain/entities/login_device_context.dart';
import 'package:flinx/features/auth/domain/entities/apple_login_nonce.dart';
import 'package:flinx/features/auth/domain/repositories/auth_login_repository.dart';
import 'package:flinx/features/auth/domain/services/google_identity_provider.dart';
import 'package:flinx/features/auth/domain/services/login_device_context_provider.dart';
import 'package:flinx/features/auth/domain/use_cases/google_login_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'passes the raw nonce and persists the returned FLINX session',
    () async {
      final calls = <String>[];
      final identityProvider = _FakeGoogleIdentityProvider(calls);
      final loginRepository = _FakeAuthLoginRepository(calls);
      final accountRepository = _FakeAccountRepository();
      final useCase = GoogleLoginUseCase(
        identityProvider: identityProvider,
        loginRepository: loginRepository,
        accountRepository: accountRepository,
        deviceContextProvider: _FakeLoginDeviceContextProvider(calls),
        requestIdGenerator: () => 'google-login-123',
      );

      final result = await useCase();

      expect(calls, ['device-context', 'nonce', 'authorize', 'login']);
      expect(identityProvider.nonce, 'raw-google-nonce');
      expect(loginRepository.nonceId, 'google-nonce-id');
      expect(loginRepository.idToken, 'id-token');
      expect(loginRepository.authorizationCode, 'authorization-code');
      expect(loginRepository.deviceId, 'installation-id');
      expect(loginRepository.requestId, 'google-login-123');
      expect(loginRepository.nonceRequestId, 'google-login-123');
      expect(accountRepository.savedProfile, result.profile);
      expect(accountRepository.savedTokenSet, result.tokenSet);
    },
  );
}

class _FakeGoogleIdentityProvider implements GoogleIdentityProvider {
  _FakeGoogleIdentityProvider(this.calls);

  final List<String> calls;
  String? nonce;

  @override
  Future<GoogleIdentityCredential> authorize({required String nonce}) async {
    calls.add('authorize');
    this.nonce = nonce;
    return const GoogleIdentityCredential(
      idToken: 'id-token',
      authorizationCode: 'authorization-code',
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
  String? idToken;
  String? authorizationCode;
  String? deviceId;
  String? requestId;

  @override
  Future<GoogleLoginNonce> getGoogleLoginNonce({
    required String requestId,
  }) async {
    calls.add('nonce');
    nonceRequestId = requestId;
    return const GoogleLoginNonce(
      nonceId: 'google-nonce-id',
      nonce: 'raw-google-nonce',
      expiresIn: Duration(minutes: 5),
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
  }) async {
    calls.add('login');
    this.nonceId = nonceId;
    this.idToken = idToken;
    this.authorizationCode = authorizationCode;
    this.deviceId = deviceId;
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
      ),
    );
  }

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
  Future<AuthLoginResult> loginWithFacebook({
    required FacebookIdentityCredential credential,
    required String? nonceId,
    required String deviceId,
    required String deviceModel,
    required String platform,
    required String appVersion,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<FacebookLoginNonce> getFacebookLoginNonce({
    required String requestId,
  }) => throw UnimplementedError();
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
