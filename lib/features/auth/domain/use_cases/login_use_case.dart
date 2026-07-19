import '../../../account/domain/repositories/account_repository.dart';
import '../entities/auth_login_result.dart';
import '../repositories/auth_crypto_repository.dart';
import '../repositories/auth_login_repository.dart';
import '../services/password_ciphertext_encryptor.dart';

class LoginUseCase {
  LoginUseCase({
    required this.loginRepository,
    required this.cryptoRepository,
    required this.encryptor,
    required this.accountRepository,
    String Function()? requestIdGenerator,
  }) : _requestIdGenerator = requestIdGenerator ?? _defaultRequestId;

  final AuthLoginRepository loginRepository;
  final AuthCryptoRepository cryptoRepository;
  final PasswordCiphertextEncryptor encryptor;
  final AccountRepository accountRepository;
  final String Function() _requestIdGenerator;

  Future<AuthLoginResult> call({
    required String email,
    required String password,
  }) async {
    final requestId = _requestIdGenerator();
    final material = await cryptoRepository.getPasswordEncryptionMaterial(
      requestId: requestId,
    );
    if (material.isExpiredAt(DateTime.now())) {
      throw StateError('Password encryption material expired.');
    }
    final result = await loginRepository.login(
      email: email,
      passwordCiphertext: encryptor.encrypt(
        plaintext: password,
        material: material,
      ),
      keyId: material.keyId,
      nonce: material.nonce,
      requestId: requestId,
    );
    await accountRepository.saveProfile(result.profile);
    await accountRepository.saveTokenSet(result.tokenSet);
    return result;
  }

  static String _defaultRequestId() =>
      'login-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
