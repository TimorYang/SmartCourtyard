import 'package:flutter_test/flutter_test.dart';
import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';

void main() {
  test('normalizes email and trims nickname', () {
    final profile = AccountProfile(
      email: '  USER@Example.COM ',
      nickname: '  FLINX User  ',
      registeredAt: DateTime.utc(2026, 1, 2),
      country: 'CN',
    );

    expect(profile.email, 'user@example.com');
    expect(profile.nickname, 'FLINX User');
  });

  test('redacts tokens from string output', () {
    const tokenSet = AccountTokenSet(
      accessToken: 'access-secret',
      refreshToken: 'refresh-secret',
    );

    expect(tokenSet.toString(), isNot(contains('access-secret')));
    expect(tokenSet.toString(), isNot(contains('refresh-secret')));
    expect(tokenSet.toString(), contains('<redacted>'));
  });
}
