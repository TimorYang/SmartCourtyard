import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/data/data_sources/account_local_data_source.dart';
import 'package:flinx/features/account/data/dto/account_profile_dto.dart';
import 'package:flinx/features/account/domain/entities/account_profile.dart';

void main() {
  test('loads the cached account profile on start', () async {
    final container = ProviderContainer(
      overrides: [
        accountLocalDataSourceProvider.overrideWithValue(
          InMemoryAccountLocalDataSource(
            initialProfile: const AccountProfileDto(
              schemaVersion: 1,
              userId: 'cached-user',
              email: 'cached@example.com',
              nickname: 'Cached User',
              registeredAtIso8601: '2026-01-02T03:04:05Z',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final profile = await container.read(accountControllerProvider.future);

    expect(profile?.email, 'cached@example.com');
    expect(profile?.nickname, 'Cached User');
  });

  test(
    'saves profile through controller and updates cached provider',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final profile = AccountProfile(
        userId: 'user-1',
        email: 'new@example.com',
        nickname: 'New User',
        registeredAt: DateTime.utc(2026, 2, 3),
        country: 'US',
      );

      await container.read(accountControllerProvider.future);
      await container
          .read(accountControllerProvider.notifier)
          .saveProfile(profile);
      container.invalidate(cachedAccountProfileProvider);
      final cached = await container.read(cachedAccountProfileProvider.future);

      expect(container.read(accountControllerProvider).requireValue, profile);
      expect(cached, profile);
    },
  );

  test('clears profile state through controller', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final profile = AccountProfile(
      userId: 'user-1',
      email: 'new@example.com',
      nickname: 'New User',
      registeredAt: DateTime.utc(2026, 2, 3),
    );

    await container.read(accountControllerProvider.future);
    await container
        .read(accountControllerProvider.notifier)
        .saveProfile(profile);
    await container.read(accountControllerProvider.notifier).clearAccount();

    expect(container.read(accountControllerProvider).requireValue, isNull);
  });

  test('updates only the in-memory profile after a successful login', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final profile = AccountProfile(
      userId: 'user-2',
      email: 'second@example.com',
      nickname: 'Second User',
      registeredAt: DateTime.utc(2026, 2, 3),
    );

    await container.read(accountControllerProvider.future);
    container
        .read(accountControllerProvider.notifier)
        .setSessionProfile(profile);

    expect(container.read(accountControllerProvider).requireValue, profile);
  });
}
