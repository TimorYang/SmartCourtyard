import 'package:flinx/features/auth/domain/entities/password_encryption_material.dart';
import 'package:flinx/features/auth/domain/entities/auth_login_result.dart';
import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';
import 'package:flinx/features/account/domain/repositories/account_repository.dart';
import 'package:flinx/features/auth/domain/repositories/auth_crypto_repository.dart';
import 'package:flinx/features/auth/domain/repositories/auth_login_repository.dart';
import 'package:flinx/features/auth/domain/services/password_ciphertext_encryptor.dart';
import 'package:flinx/features/auth/domain/services/login_device_context_provider.dart';
import 'package:flinx/features/auth/domain/entities/login_device_context.dart';
import 'package:flinx/features/auth/domain/use_cases/login_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'fetches one-time material then submits an encrypted login with one request id',
    () async {
      final cryptoRepository = _FakeCryptoRepository();
      final loginRepository = _FakeLoginRepository();
      final accountRepository = _FakeAccountRepository();
      final useCase = LoginUseCase(
        loginRepository: loginRepository,
        cryptoRepository: cryptoRepository,
        encryptor: const _FakeEncryptor(),
        accountRepository: accountRepository,
        deviceContextProvider: const _FakeLoginDeviceContextProvider(),
        requestIdGenerator: () => 'login-123',
      );

      await useCase(email: 'alice@example.com', password: 'secret');

      expect(cryptoRepository.requestId, 'login-123');
      expect(loginRepository.requestId, 'login-123');
      expect(loginRepository.email, 'alice@example.com');
      expect(loginRepository.keyId, 'app-password-key-v1');
      expect(loginRepository.nonce, 'one-time-nonce');
      expect(loginRepository.passwordCiphertext, 'encrypted:secret');
      expect(loginRepository.deviceId, 'installation-id');
      expect(loginRepository.deviceModel, 'iPhone17,2');
      expect(loginRepository.platform, 'IOS');
      expect(loginRepository.appVersion, '1.0.0');
      expect(accountRepository.savedTokenSet?.accessToken, 'access-token');
      expect(accountRepository.savedTokenSet?.refreshToken, 'refresh-token');
    },
  );
}

class _FakeCryptoRepository implements AuthCryptoRepository {
  String? requestId;

  @override
  Future<PasswordEncryptionMaterial> getPasswordEncryptionMaterial({
    required String requestId,
  }) async {
    this.requestId = requestId;
    return PasswordEncryptionMaterial(
      keyId: 'app-password-key-v1',
      algorithm: PasswordEncryptionMaterial.rsaOaepSha256,
      publicKeyBase64: 'unused',
      nonce: 'one-time-nonce',
      expiresIn: const Duration(minutes: 5),
      requestId: requestId,
      issuedAt: DateTime.now().toUtc(),
    );
  }
}

class _FakeLoginRepository implements AuthLoginRepository {
  String? email;
  String? passwordCiphertext;
  String? keyId;
  String? nonce;
  String? deviceId;
  String? deviceModel;
  String? platform;
  String? appVersion;
  String? requestId;

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
  }) async {
    this.email = email;
    this.passwordCiphertext = passwordCiphertext;
    this.keyId = keyId;
    this.nonce = nonce;
    this.requestId = requestId;
    this.deviceId = deviceId;
    this.deviceModel = deviceModel;
    this.platform = platform;
    this.appVersion = appVersion;
    return AuthLoginResult(
      tokenSet: const AccountTokenSet(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
      profile: AccountProfile(
        userId: '2',
        email: email,
        nickname: 'Alice',
        country: 'NL',
      ),
    );
  }

  @override
  Future<AuthLoginResult> loginWithApple({
    required String identityToken,
    required String requestId,
  }) => throw UnimplementedError();
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
  AccountTokenSet? savedTokenSet;
  AccountProfile? savedProfile;

  @override
  Future<void> saveProfile(AccountProfile profile) async {
    savedProfile = profile;
  }

  @override
  Future<void> clearAccount() => throw UnimplementedError();

  @override
  Future<void> confirmAccountDeletion({required String requestId}) =>
      throw UnimplementedError();

  @override
  Future<AccountProfile?> readCachedProfile() => throw UnimplementedError();

  @override
  Future<AccountTokenSet?> readTokenSet() => throw UnimplementedError();

  @override
  Future<void> saveTokenSet(AccountTokenSet tokenSet) async {
    savedTokenSet = tokenSet;
  }

  @override
  Stream<AccountProfile?> watchProfile() => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEncryptor implements PasswordCiphertextEncryptor {
  const _FakeEncryptor();

  @override
  String encrypt({
    required String plaintext,
    required PasswordEncryptionMaterial material,
  }) => 'encrypted:$plaintext';
}
