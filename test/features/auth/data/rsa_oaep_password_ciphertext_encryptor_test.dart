import 'dart:convert';

import 'package:flinx/features/auth/data/services/rsa_oaep_password_ciphertext_encryptor.dart';
import 'package:flinx/features/auth/domain/entities/password_encryption_material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encrypts with the public key returned by the password crypto API', () {
    const publicKey =
        'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnjvJot9rAM/yQ/SG/23dZ3UcdDPhQcwd5GRD1ch2eDdRiMoXEVGveNIxKr+lgoFOf4l5FgRNopFNNB0gi9k7p88pZUNhimmejbe5x7zJ7P7I8WkEYUYV5J034qRxSiiOFyL4WvKW4DZYp/a9YghbdE7T2wr0UH/3WO4Ex/C4U3YAfquwpDwt1mEbxMPeah9mbSlc54uv70WVgFrYlcQEkZUhHcY63o5+RSx0c9t9C6YOuWgE5HKffsuDX1pKcnMMA/5A18lRhpMWJPXt5pVmKItlS/lclyAL18T5HLVY8nMLGAJHxONSeC1kh+o31u0CfHGl75kQJc4PiKqU79cL/QIDAQAB';
    final material = PasswordEncryptionMaterial(
      keyId: 'app-password-key-v1',
      algorithm: PasswordEncryptionMaterial.rsaOaepSha256,
      publicKeyBase64: publicKey,
      nonce: '21b35ab15f0db86064053d109e069dbb',
      expiresIn: const Duration(minutes: 10),
      requestId: 'test-request',
      issuedAt: DateTime.utc(2026),
    );

    final encryptor = RsaOaepPasswordCiphertextEncryptor(
      clock: () => DateTime.utc(2026, 7, 12, 8),
    );

    final ciphertext = encryptor.encrypt(
      plaintext: '12345678',
      material: material,
    );

    expect(base64Decode(ciphertext), hasLength(256));
    expect(
      encryptor.encrypt(plaintext: '12345678', material: material),
      isNot(ciphertext),
      reason: 'RSA-OAEP must use fresh random padding for every encryption.',
    );
  });
}
