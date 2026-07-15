import '../repositories/auth_crypto_repository.dart';
import '../repositories/auth_password_reset_repository.dart';
import '../services/password_ciphertext_encryptor.dart';

class CompletePasswordResetUseCase {
  CompletePasswordResetUseCase({
    required this.passwordResetRepository,
    required this.cryptoRepository,
    required this.encryptor,
    String Function()? requestIdGenerator,
  }) : _requestIdGenerator = requestIdGenerator ?? _defaultRequestId;

  final AuthPasswordResetRepository passwordResetRepository;
  final AuthCryptoRepository cryptoRepository;
  final PasswordCiphertextEncryptor encryptor;
  final String Function() _requestIdGenerator;

  Future<void> call({
    required String passwordResetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final requestId = _requestIdGenerator();
    final material = await cryptoRepository.getPasswordEncryptionMaterial(
      requestId: requestId,
    );
    if (material.isExpiredAt(DateTime.now())) {
      throw StateError('Password encryption material expired.');
    }
    await passwordResetRepository.completePasswordReset(
      passwordResetToken: passwordResetToken,
      newPasswordCiphertext: encryptor.encrypt(
        plaintext: newPassword,
        material: material,
      ),
      confirmPasswordCiphertext: encryptor.encrypt(
        plaintext: confirmPassword,
        material: material,
      ),
      keyId: material.keyId,
      nonce: material.nonce,
      requestId: requestId,
    );
  }

  static String _defaultRequestId() =>
      'password-reset-complete-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
