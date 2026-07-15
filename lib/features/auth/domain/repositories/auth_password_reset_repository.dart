import '../entities/password_reset_verification.dart';

abstract interface class AuthPasswordResetRepository {
  Future<void> sendEmailCode({
    required String email,
    required String requestId,
  });

  Future<PasswordResetVerification> verifyEmailCode({
    required String email,
    required String code,
    required String requestId,
  });

  Future<void> completePasswordReset({
    required String passwordResetToken,
    required String newPasswordCiphertext,
    required String confirmPasswordCiphertext,
    required String keyId,
    required String nonce,
    required String requestId,
  });
}
