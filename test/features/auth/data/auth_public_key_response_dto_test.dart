import 'package:flinx/features/auth/data/dto/auth_public_key_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

void main() {
  test(
    'converts the server expiresIn string without changing the wire format',
    () {
      final dto = AuthPublicKeyResponseDto.fromJson(const {
        'keyId': 'key-v1',
        'algorithm': 'RSA-OAEP-256',
        'publicKey': 'public-key',
        'nonce': 'nonce',
        'expiresIn': '600',
      });

      expect(dto.expiresInSeconds, 600);
    },
  );

  test('rejects a missing required response field', () {
    expect(
      () => AuthPublicKeyResponseDto.fromJson(const {
        'keyId': 'key-v1',
        'algorithm': 'RSA-OAEP-256',
        'nonce': 'nonce',
        'expiresIn': 600,
      }),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });

  test(
    'ignores unknown server fields while preserving known protocol fields',
    () {
      final dto = AuthPublicKeyResponseDto.fromJson(const {
        'keyId': 'key-v1',
        'algorithm': 'RSA-OAEP-256',
        'publicKey': 'public-key',
        'nonce': 'nonce',
        'expiresIn': 600,
        'serverAddedField': 'safe-to-ignore',
      });

      expect(dto.keyId, 'key-v1');
      expect(dto.expiresInSeconds, 600);
    },
  );
}
