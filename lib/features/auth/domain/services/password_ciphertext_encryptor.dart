import '../entities/password_encryption_material.dart';

abstract interface class PasswordCiphertextEncryptor {
  String encrypt({
    required String plaintext,
    required PasswordEncryptionMaterial material,
  });
}
