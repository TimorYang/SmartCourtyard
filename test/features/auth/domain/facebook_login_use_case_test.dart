import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';
import 'package:flinx/features/account/domain/repositories/account_repository.dart';
import 'package:flinx/features/auth/domain/entities/auth_login_result.dart';
import 'package:flinx/features/auth/domain/entities/facebook_identity_credential.dart';
import 'package:flinx/features/auth/domain/entities/facebook_login_nonce.dart';
import 'package:flinx/features/auth/domain/entities/login_device_context.dart';
import 'package:flinx/features/auth/domain/repositories/auth_login_repository.dart';
import 'package:flinx/features/auth/domain/services/facebook_identity_provider.dart';
import 'package:flinx/features/auth/domain/services/login_device_context_provider.dart';
import 'package:flinx/features/auth/domain/use_cases/facebook_login_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uses the iOS nonce before Limited Login and persists the session',
    () async {
      final calls = <String>[];
      final identityProvider = _FakeFacebookIdentityProvider(
        calls,
        credential: const FacebookIdentityCredential(
          kind: FacebookTokenKind.authenticationToken,
          tokenString: 'authentication-token',
        ),
      );
      final loginRepository = _FakeFacebookLoginRepository(calls);
      final accountRepository = _FakeAccountRepository(calls);
      final useCase = FacebookLoginUseCase(
        identityProvider: identityProvider,
        loginRepository: loginRepository,
        accountRepository: accountRepository,
        deviceContextProvider: _FakeLoginDeviceContextProvider(calls, 'IOS'),
        requestIdGenerator: () => 'facebook-login-ios-123',
      );

      final result = await useCase();

      expect(calls, [
        'availability',
        'device-context',
        'nonce',
        'authorize',
        'login',
        'profile',
        'token',
      ]);
      expect(identityProvider.platform, FacebookLoginPlatform.ios);
      expect(identityProvider.nonce, 'facebook-raw-nonce');
      expect(loginRepository.nonceId, 'facebook-nonce-id');
      expect(
        loginRepository.credential?.kind,
        FacebookTokenKind.authenticationToken,
      );
      expect(loginRepository.requestId, 'facebook-login-ios-123');
      expect(accountRepository.savedProfile, result.profile);
      expect(accountRepository.savedTokenSet, result.tokenSet);
    },
  );

  test(
    'does not request a nonce on Android and uses the access token',
    () async {
      final calls = <String>[];
      final identityProvider = _FakeFacebookIdentityProvider(
        calls,
        credential: const FacebookIdentityCredential(
          kind: FacebookTokenKind.accessToken,
          tokenString: 'access-token',
        ),
      );
      final loginRepository = _FakeFacebookLoginRepository(calls);
      final accountRepository = _FakeAccountRepository(calls);
      final useCase = FacebookLoginUseCase(
        identityProvider: identityProvider,
        loginRepository: loginRepository,
        accountRepository: accountRepository,
        deviceContextProvider: _FakeLoginDeviceContextProvider(
          calls,
          'ANDROID',
        ),
        requestIdGenerator: () => 'facebook-login-android-123',
      );

      await useCase();

      expect(calls, [
        'availability',
        'device-context',
        'authorize',
        'login',
        'profile',
        'token',
      ]);
      expect(identityProvider.platform, FacebookLoginPlatform.android);
      expect(identityProvider.nonce, isNull);
      expect(loginRepository.nonceId, isNull);
      expect(loginRepository.credential?.kind, FacebookTokenKind.accessToken);
    },
  );
}

class _FakeFacebookIdentityProvider implements FacebookIdentityProvider {
  _FakeFacebookIdentityProvider(this.calls, {required this.credential});

  final List<String> calls;
  final FacebookIdentityCredential credential;
  FacebookLoginPlatform? platform;
  String? nonce;

  @override
  Future<bool> isAvailable() async {
    calls.add('availability');
    return true;
  }

  @override
  Future<FacebookIdentityCredential> authorize({
    required FacebookLoginPlatform platform,
    String? nonce,
  }) async {
    calls.add('authorize');
    this.platform = platform;
    this.nonce = nonce;
    return credential;
  }
}

class _FakeFacebookLoginRepository implements AuthLoginRepository {
  _FakeFacebookLoginRepository(this.calls);

  final List<String> calls;
  FacebookIdentityCredential? credential;
  String? nonceId;
  String? requestId;

  @override
  Future<FacebookLoginNonce> getFacebookLoginNonce({
    required String requestId,
  }) async {
    calls.add('nonce');
    this.requestId = requestId;
    return const FacebookLoginNonce(
      nonceId: 'facebook-nonce-id',
      nonce: 'facebook-raw-nonce',
      expiresIn: Duration(minutes: 5),
    );
  }

  @override
  Future<AuthLoginResult> loginWithFacebook({
    required FacebookIdentityCredential credential,
    required String? nonceId,
    required String deviceId,
    required String deviceModel,
    required String platform,
    required String appVersion,
    required String requestId,
  }) async {
    calls.add('login');
    this.credential = credential;
    this.nonceId = nonceId;
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLoginDeviceContextProvider implements LoginDeviceContextProvider {
  const _FakeLoginDeviceContextProvider(this.calls, this.platform);

  final List<String> calls;
  final String platform;

  @override
  Future<LoginDeviceContext> read() async {
    calls.add('device-context');
    return LoginDeviceContext(
      deviceId: 'installation-id',
      deviceModel: platform == 'IOS' ? 'iPhone17,2' : 'Pixel 9',
      platform: platform,
      appVersion: '1.0.0',
    );
  }
}

class _FakeAccountRepository implements AccountRepository {
  _FakeAccountRepository(this.calls);

  final List<String> calls;
  AccountProfile? savedProfile;
  AccountTokenSet? savedTokenSet;

  @override
  Future<void> saveProfile(AccountProfile profile) async {
    calls.add('profile');
    savedProfile = profile;
  }

  @override
  Future<void> saveTokenSet(AccountTokenSet tokenSet) async {
    calls.add('token');
    savedTokenSet = tokenSet;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
