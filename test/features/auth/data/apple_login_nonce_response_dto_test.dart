import 'package:flinx/features/auth/data/dto/apple_login_nonce_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses expiresIn when the server returns a numeric string', () {
    final dto = AppleLoginNonceResponseDto.fromJson(const {
      'nonceId': '0mWNM_RhR-LosJ3KUF67Rw',
      'nonce': 'Q1D09cmRULHLQwOh-udhBiVrUTINvKp9GAcLhtPwyiQ',
      'expiresIn': '300',
    });

    expect(dto.nonceId, '0mWNM_RhR-LosJ3KUF67Rw');
    expect(dto.nonce, 'Q1D09cmRULHLQwOh-udhBiVrUTINvKp9GAcLhtPwyiQ');
    expect(dto.expiresInSeconds, 300);
  });

  test('continues to parse a numeric expiresIn value', () {
    final dto = AppleLoginNonceResponseDto.fromJson(const {
      'nonceId': 'nonce-id',
      'nonce': 'raw-nonce',
      'expiresIn': 300,
    });

    expect(dto.expiresInSeconds, 300);
  });
}
