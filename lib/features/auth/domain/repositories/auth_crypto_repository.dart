import '../entities/password_encryption_material.dart';

abstract interface class AuthCryptoRepository {
  Future<PasswordEncryptionMaterial> getPasswordEncryptionMaterial({
    required String requestId,
  });
}
