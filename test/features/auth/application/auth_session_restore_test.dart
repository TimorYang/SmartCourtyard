import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/data/data_sources/account_local_data_source.dart';
import 'package:flinx/features/account/data/data_sources/account_secure_data_source.dart';
import 'package:flinx/features/account/data/dto/account_profile_dto.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not restore a session when the cached token is missing', () async {
    final container = ProviderContainer(
      overrides: [
        accountLocalDataSourceProvider.overrideWithValue(
          InMemoryAccountLocalDataSource(
            initialProfile: const AccountProfileDto(
              schemaVersion: 1,
              userId: 'user-1',
              email: 'user@example.com',
              nickname: 'User',
              registeredAtIso8601: '2026-01-02T03:04:05Z',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final session = await container.read(authSessionProvider.future);

    expect(session.isAuthenticated, isFalse);
    expect(session.userId, isNull);
  });

  test('does not restore a session when the cached token is expired', () async {
    final container = ProviderContainer(
      overrides: [
        accountLocalDataSourceProvider.overrideWithValue(
          InMemoryAccountLocalDataSource(
            initialProfile: const AccountProfileDto(
              schemaVersion: 1,
              userId: 'user-1',
              email: 'user@example.com',
              nickname: 'User',
              registeredAtIso8601: '2026-01-02T03:04:05Z',
            ),
          ),
        ),
        accountSecureDataSourceProvider.overrideWithValue(
          _InitialTokenDataSource(
            AccountTokenSet(
              accessToken: 'expired-access',
              expiresAt: DateTime.utc(2020),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final session = await container.read(authSessionProvider.future);

    expect(session.isAuthenticated, isFalse);
    expect(session.userId, isNull);
  });
}

class _InitialTokenDataSource extends InMemoryAccountSecureDataSource {
  _InitialTokenDataSource(this.initialTokenSet);

  final AccountTokenSet initialTokenSet;

  @override
  Future<AccountTokenSet?> readTokenSet() async {
    return initialTokenSet;
  }
}
