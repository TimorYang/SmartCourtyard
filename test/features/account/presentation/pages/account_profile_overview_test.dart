import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/account_overview.dart';
import 'package:flinx/features/account/domain/repositories/account_overview_repository.dart';
import 'package:flinx/features/account/presentation/pages/account_profile_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows refreshed account overview data and no update count', (
    tester,
  ) async {
    final repository = _FakeAccountOverviewRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountOverviewRepositoryProvider.overrideWithValue(repository),
          accountOverviewAutoRefreshProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountProfilePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(repository.refreshCount, 1);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('2026-07-28 20:30:00'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(AccountProfileKeys.checkForUpdatesMenuItem),
        matching: find.text('2'),
      ),
      findsNothing,
    );
  });
}

class _FakeAccountOverviewRepository implements AccountOverviewRepository {
  var refreshCount = 0;

  @override
  Future<void> clearCachedOverview() async {}

  @override
  Future<AccountOverview?> readCachedOverview() async => null;

  @override
  Future<AccountOverview> refreshOverview({required String requestId}) async {
    refreshCount++;
    return AccountOverview(
      nickname: 'Alex',
      ownedDoorCount: 3,
      sharedDoorCount: 2,
      receivingDoorCount: 1,
      refreshedAt: DateTime(2026, 7, 28, 20, 30),
    );
  }
}
