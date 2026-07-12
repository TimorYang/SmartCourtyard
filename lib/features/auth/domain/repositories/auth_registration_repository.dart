import '../entities/registration_verification.dart';

abstract interface class AuthRegistrationRepository {
  Future<void> sendEmailCode({
    required String email,
    required String requestId,
  });

  Future<RegistrationVerification> verifyEmailCode({
    required String email,
    required String code,
    required String requestId,
  });

  Future<void> completeRegistration({
    required String registrationToken,
    required String passwordCiphertext,
    required String confirmPasswordCiphertext,
    required String keyId,
    required String nonce,
    required String locale,
    required String timezone,
    String? regionCode,
    required String requestId,
  });
}
