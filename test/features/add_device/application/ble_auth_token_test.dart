import 'package:flinx/features/add_device/application/ble_auth_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds the authentication token from decoded AES key bytes', () {
    expect(
      buildBleAuthenticationToken('1BEE89494F466512FF584DDF85B39AA6'),
      'AF035A47A6ABB06B884F28409EFB8E44',
    );
  });

  test('rejects an AES key that is not 16 bytes encoded as hexadecimal', () {
    expect(
      () => buildBleAuthenticationToken('invalid-key'),
      throwsA(isA<FormatException>()),
    );
  });
}
