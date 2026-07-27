import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flinx/core/network/access_token_cache.dart';
import 'package:flinx/features/account/data/data_sources/account_local_data_source.dart';
import 'package:flinx/features/account/data/data_sources/account_secure_data_source.dart';
import 'package:flinx/features/account/data/mappers/account_profile_mapper.dart';
import 'package:flinx/features/account/data/repositories/account_repository_impl.dart';
import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';

void main() {
  tearDown(AccessTokenCache.clear);

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
      userId: 'user-1',
      email: 'user@example.com',
      nickname: 'Alice',
      registeredAt: DateTime.utc(2026, 1, 2),
      country: 'CN',
    );

    await repository.saveProfile(profile);

    expect(await repository.readCachedProfile(), profile);
  });

  test('restores cached profile from disk on cold start', () async {
    final directory = await Directory.systemTemp.createTemp(
      'flinx_account_profile_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final profileFile = File('${directory.path}/account_profile.json');
    final profile = AccountProfile(
      userId: 'user-1',
      email: 'user@example.com',
      nickname: 'Alice',
      registeredAt: DateTime.utc(2026, 1, 2),
      country: 'US',
    );

    final firstLaunchRepository = AccountRepositoryImpl(
      localDataSource: JsonFileAccountLocalDataSource(profileFile: profileFile),
      secureDataSource: InMemoryAccountSecureDataSource(),
    );
    await firstLaunchRepository.saveProfile(profile);

    final coldStartRepository = AccountRepositoryImpl(
      localDataSource: JsonFileAccountLocalDataSource(profileFile: profileFile),
      secureDataSource: InMemoryAccountSecureDataSource(),
    );

    expect(await coldStartRepository.readCachedProfile(), profile);
  });

  test('migrates a cached profile from the legacy storage directory', () async {
    final directory = await Directory.systemTemp.createTemp(
      'flinx_account_profile_migration_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final legacyProfileFile = File(
      '${directory.path}/legacy/account_profile.json',
    );
    final persistentProfileFile = File(
      '${directory.path}/support/account_profile.json',
    );
    final profile = AccountProfile(
      userId: 'user-1',
      email: 'user@example.com',
      nickname: 'Alice',
      registeredAt: DateTime.utc(2026, 1, 2),
    );
    final legacySource = JsonFileAccountLocalDataSource(
      profileFile: legacyProfileFile,
    );
    await legacySource.saveProfile(profile.toLocalDto());

    final persistentSource = JsonFileAccountLocalDataSource(
      profileFile: persistentProfileFile,
      legacyProfileFiles: [legacyProfileFile],
    );

    expect((await persistentSource.readProfile())?.toDomain(), profile);
    expect(await persistentProfileFile.exists(), isTrue);
    expect(await legacyProfileFile.exists(), isFalse);
  });

  test(
    'does not overwrite a persistent profile with a legacy profile',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'flinx_account_profile_existing_test_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final legacyProfileFile = File(
        '${directory.path}/legacy/account_profile.json',
      );
      final persistentProfileFile = File(
        '${directory.path}/support/account_profile.json',
      );
      final persistentProfile = AccountProfile(
        userId: 'persistent-user',
        email: 'persistent@example.com',
        nickname: 'Persistent',
      );
      final legacyProfile = AccountProfile(
        userId: 'legacy-user',
        email: 'legacy@example.com',
        nickname: 'Legacy',
      );
      await JsonFileAccountLocalDataSource(
        profileFile: persistentProfileFile,
      ).saveProfile(persistentProfile.toLocalDto());
      await JsonFileAccountLocalDataSource(
        profileFile: legacyProfileFile,
      ).saveProfile(legacyProfile.toLocalDto());

      final source = JsonFileAccountLocalDataSource(
        profileFile: persistentProfileFile,
        legacyProfileFiles: [legacyProfileFile],
      );

      expect((await source.readProfile())?.toDomain(), persistentProfile);
      expect(await legacyProfileFile.exists(), isTrue);
    },
  );

  test('returns null for a malformed persisted profile', () async {
    final directory = await Directory.systemTemp.createTemp(
      'flinx_account_profile_malformed_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final profileFile = File('${directory.path}/account_profile.json');
    await profileFile.parent.create(recursive: true);
    await profileFile.writeAsString('{not valid json');

    final source = JsonFileAccountLocalDataSource(profileFile: profileFile);

    expect(await source.readProfile(), isNull);
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
      userId: 'user-1',
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

  test(
    'caches an expired access token so the network layer can refresh it',
    () async {
      final secureDataSource = InMemoryAccountSecureDataSource();
      final repository = AccountRepositoryImpl(
        localDataSource: InMemoryAccountLocalDataSource(),
        secureDataSource: secureDataSource,
      );
      await secureDataSource.saveTokenSet(
        AccountTokenSet(
          accessToken: 'expired-access',
          expiresAt: DateTime.utc(2020),
        ),
      );

      expect(await repository.readTokenSet(), isNotNull);
      expect(AccessTokenCache.value, 'expired-access');
      expect(AccessTokenCache.requiresRefresh, isTrue);
    },
  );
}
