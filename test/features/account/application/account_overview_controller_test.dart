import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/account_overview.dart';
import 'package:flinx/features/account/domain/repositories/account_overview_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'loads cached data then replaces it with a successful refresh',
    () async {
      final cached = _overview('Cached', 1);
      final refreshed = _overview('Alex', 2);
      final repository = _FakeAccountOverviewRepository(
        cached: cached,
        refreshed: refreshed,
      );
      final container = ProviderContainer(
        overrides: [
          accountOverviewRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(accountOverviewControllerProvider.future),
        cached,
      );

      await container
          .read(accountOverviewControllerProvider.notifier)
          .refresh();

      expect(
        container.read(accountOverviewControllerProvider).requireValue,
        refreshed,
      );
      expect(repository.requestId, startsWith('account-overview-'));
    },
  );

  test('retains cached data after a refresh failure', () async {
    final cached = _overview('Cached', 1);
    final repository = _FakeAccountOverviewRepository(
      cached: cached,
      refreshError: const AppError(
        code: AppErrorCode.networkUnavailable,
        messageKey: 'account.overview.networkUnavailable',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        accountOverviewRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(accountOverviewControllerProvider.future);
    await expectLater(
      container.read(accountOverviewControllerProvider.notifier).refresh(),
      throwsA(isA<AppError>()),
    );

    expect(
      container.read(accountOverviewControllerProvider).requireValue,
      cached,
    );
  });
}

AccountOverview _overview(String nickname, int count) => AccountOverview(
  nickname: nickname,
  ownedDoorCount: count,
  sharedDoorCount: count,
  receivingDoorCount: count,
  refreshedAt: DateTime(2026, 7, 28, 20, 30),
);

class _FakeAccountOverviewRepository implements AccountOverviewRepository {
  _FakeAccountOverviewRepository({
    this.cached,
    this.refreshed,
    this.refreshError,
  });

  final AccountOverview? cached;
  final AccountOverview? refreshed;
  final Object? refreshError;
  String? requestId;

  @override
  Future<void> clearCachedOverview() async {}

  @override
  Future<AccountOverview?> readCachedOverview() async => cached;

  @override
  Future<AccountOverview> refreshOverview({required String requestId}) async {
    this.requestId = requestId;
    if (refreshError != null) {
      throw refreshError!;
    }
    return refreshed!;
  }
}
