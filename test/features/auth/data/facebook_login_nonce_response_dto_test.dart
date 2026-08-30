import 'package:flinx/features/auth/data/dto/facebook_login_nonce_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses nonce fields and numeric expiry values', () {
    final dto = FacebookLoginNonceResponseDto.fromJson({
      'nonceId': 'nonce-id',
      'nonce': 'raw-nonce',
      'expiresIn': 300.9,
    });

    expect(dto.nonceId, 'nonce-id');
    expect(dto.nonce, 'raw-nonce');
    expect(dto.expiresInSeconds, 300);
  });

  test('parses string expiry values and defaults malformed fields', () {
    final dto = FacebookLoginNonceResponseDto.fromJson({
      'nonceId': null,
      'nonce': 42,
      'expiresIn': 'not-a-duration',
    });

    expect(dto.nonceId, isEmpty);
    expect(dto.nonce, isEmpty);
    expect(dto.expiresInSeconds, 0);
  });
}
