import 'package:flinx/features/auth/domain/entities/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts only passwords with 8-16 characters', () {
    expect(PasswordPolicy.isLengthValid('1234567'), isFalse);
    expect(PasswordPolicy.isLengthValid('12345678'), isTrue);
    expect(PasswordPolicy.isLengthValid('1234567890123456'), isTrue);
    expect(PasswordPolicy.isLengthValid('12345678901234567'), isFalse);
  });

  test('requires 8-16 characters with uppercase, lowercase, and a number', () {
    expect(PasswordPolicy.isValid('Password123'), isTrue);
    expect(PasswordPolicy.isValid('Abcdefgh1'), isTrue);
    expect(PasswordPolicy.isValid('password123'), isFalse);
    expect(PasswordPolicy.isValid('PASSWORD123'), isFalse);
    expect(PasswordPolicy.isValid('Password'), isFalse);
    expect(PasswordPolicy.isValid('Pass123'), isFalse);
    expect(PasswordPolicy.isValid('Password123456789'), isFalse);
  });
}
