import '../entities/account_overview.dart';

abstract class AccountOverviewRepository {
  Future<AccountOverview?> readCachedOverview();

  Future<AccountOverview> refreshOverview({required String requestId});

  Future<void> clearCachedOverview();
}
