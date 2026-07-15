import 'package:flinx/features/auth/domain/entities/password_encryption_material.dart';
import 'package:flinx/features/auth/domain/entities/password_reset_verification.dart';
import 'package:flinx/features/auth/domain/repositories/auth_crypto_repository.dart';
import 'package:flinx/features/auth/domain/repositories/auth_password_reset_repository.dart';
import 'package:flinx/features/auth/domain/services/password_ciphertext_encryptor.dart';
import 'package:flinx/features/auth/domain/use_cases/complete_password_reset_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uses one request id for crypto and the encrypted reset request',
    () async {
      final cryptoRepository = _FakeCryptoRepository();
      final passwordResetRepository = _FakePasswordResetRepository();
      final useCase = CompletePasswordResetUseCase(
        passwordResetRepository: passwordResetRepository,
        cryptoRepository: cryptoRepository,
        encryptor: const _FakeEncryptor(),
        requestIdGenerator: () => 'reset-123',
      );

      await useCase(
        passwordResetToken: 'one-time-token',
        newPassword: '12345678',
        confirmPassword: '12345678',
      );

      expect(cryptoRepository.requestId, 'reset-123');
      expect(passwordResetRepository.requestId, 'reset-123');
      expect(passwordResetRepository.keyId, 'app-password-key-v1');
      expect(passwordResetRepository.nonce, 'nonce');
      expect(passwordResetRepository.newCiphertext, 'encrypted:12345678');
      expect(passwordResetRepository.confirmCiphertext, 'encrypted:12345678');
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
      publicKeyBase64: 'public-key',
      nonce: 'nonce',
      expiresIn: const Duration(minutes: 5),
      requestId: requestId,
      issuedAt: DateTime.now().toUtc(),
    );
  }
}

class _FakePasswordResetRepository implements AuthPasswordResetRepository {
  String? requestId;
  String? keyId;
  String? nonce;
  String? newCiphertext;
  String? confirmCiphertext;

  @override
  Future<void> completePasswordReset({
    required String passwordResetToken,
    required String newPasswordCiphertext,
    required String confirmPasswordCiphertext,
    required String keyId,
    required String nonce,
    required String requestId,
  }) async {
    this.requestId = requestId;
    this.keyId = keyId;
    this.nonce = nonce;
    newCiphertext = newPasswordCiphertext;
    confirmCiphertext = confirmPasswordCiphertext;
  }

  @override
  Future<void> sendEmailCode({
    required String email,
    required String requestId,
  }) async {}

  @override
  Future<PasswordResetVerification> verifyEmailCode({
    required String email,
    required String code,
    required String requestId,
  }) async => const PasswordResetVerification(
    passwordResetToken: 'one-time-token',
    expiresIn: Duration(minutes: 10),
  );
}

class _FakeEncryptor implements PasswordCiphertextEncryptor {
  const _FakeEncryptor();

  @override
  String encrypt({
    required String plaintext,
    required PasswordEncryptionMaterial material,
  }) => 'encrypted:$plaintext';
}
