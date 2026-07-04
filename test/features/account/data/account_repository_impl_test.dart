import 'package:flutter_test/flutter_test.dart';
import 'package:flinx/features/account/data/data_sources/account_local_data_source.dart';
import 'package:flinx/features/account/data/data_sources/account_secure_data_source.dart';
import 'package:flinx/features/account/data/repositories/account_repository_impl.dart';
import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';

void main() {
  test('returns null when no profile is cached', () async {
    final repository = AccountRepositoryImpl(
      localDataSource: InMemoryAccountLocalDataSource(),
      secureDataSource: InMemoryAccountSecureDataSource(),
    );

    expect(await repository.readCachedProfile(), isNull);
  });

  test('saves and reads cached profile', () async {
    final repository = AccountRepositoryImpl(
      localDataSource: InMemoryAccountLocalDataSource(),
      secureDataSource: InMemoryAccountSecureDataSource(),
    );
    final profile = AccountProfile(
      email: 'user@example.com',
      nickname: 'Alice',
      registeredAt: DateTime.utc(2026, 1, 2),
      country: 'CN',
    );

    await repository.saveProfile(profile);

    expect(await repository.readCachedProfile(), profile);
  });

  test('stores tokens only in secure data source', () async {
    final localDataSource = InMemoryAccountLocalDataSource();
    final secureDataSource = InMemoryAccountSecureDataSource();
    final repository = AccountRepositoryImpl(
      localDataSource: localDataSource,
      secureDataSource: secureDataSource,
    );
    const tokenSet = AccountTokenSet(accessToken: 'access-secret');

    await repository.saveTokenSet(tokenSet);

    expect(await repository.readTokenSet(), tokenSet);
    expect(await localDataSource.readProfile(), isNull);
  });

  test('clearAccount clears profile cache and token set', () async {
    final repository = AccountRepositoryImpl(
      localDataSource: InMemoryAccountLocalDataSource(),
      secureDataSource: InMemoryAccountSecureDataSource(),
    );
    final profile = AccountProfile(
      email: 'user@example.com',
      nickname: 'Alice',
      registeredAt: DateTime.utc(2026, 1, 2),
    );

    await repository.saveProfile(profile);
    await repository.saveTokenSet(
      const AccountTokenSet(accessToken: 'access-secret'),
    );
    await repository.clearAccount();

    expect(await repository.readCachedProfile(), isNull);
    expect(await repository.readTokenSet(), isNull);
  });
}
