import '../entities/registration_device_context.dart';
import '../repositories/auth_crypto_repository.dart';
import '../repositories/auth_registration_repository.dart';
import '../services/password_ciphertext_encryptor.dart';

class CompleteRegistrationUseCase {
  CompleteRegistrationUseCase({
    required this.registrationRepository,
    required this.cryptoRepository,
    required this.encryptor,
    String Function()? requestIdGenerator,
  }) : _requestIdGenerator = requestIdGenerator ?? _defaultRequestId;

  final AuthRegistrationRepository registrationRepository;
  final AuthCryptoRepository cryptoRepository;
  final PasswordCiphertextEncryptor encryptor;
  final String Function() _requestIdGenerator;

  Future<void> call({
    required String registrationToken,
    required String password,
    required String confirmPassword,
    required RegistrationDeviceContext deviceContext,
  }) async {
    final requestId = _requestIdGenerator();
    final material = await cryptoRepository.getPasswordEncryptionMaterial(
      requestId: requestId,
    );
    if (material.isExpiredAt(DateTime.now())) {
      throw StateError('Password encryption material expired.');
    }
    await registrationRepository.completeRegistration(
      registrationToken: registrationToken,
      passwordCiphertext: encryptor.encrypt(
        plaintext: password,
        material: material,
      ),
      confirmPasswordCiphertext: encryptor.encrypt(
        plaintext: confirmPassword,
        material: material,
      ),
      keyId: material.keyId,
      nonce: material.nonce,
      locale: deviceContext.locale,
      timezone: deviceContext.timezone,
      regionCode: deviceContext.regionCode,
      requestId: requestId,
    );
  }

  static String _defaultRequestId() =>
      'register-complete-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
