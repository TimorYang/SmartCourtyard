import 'package:flinx/features/auth/data/dto/google_login_nonce_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses expiresIn when the server returns a numeric string', () {
    final dto = GoogleLoginNonceResponseDto.fromJson(const {
      'nonceId': 'google-nonce-id',
      'nonce': 'raw-google-nonce',
      'expiresIn': '300',
    });

    expect(dto.nonceId, 'google-nonce-id');
    expect(dto.nonce, 'raw-google-nonce');
    expect(dto.expiresInSeconds, 300);
  });
}
