import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/account_overview.dart';
import '../domain/repositories/account_overview_repository.dart';
import 'providers.dart';

class AccountOverviewController extends AsyncNotifier<AccountOverview?> {
  AccountOverviewRepository get _repository =>
      ref.read(accountOverviewRepositoryProvider);

  @override
  Future<AccountOverview?> build() => _repository.readCachedOverview();

  Future<void> refresh() async {
    final cachedOverview =
        state.asData?.value ?? await _repository.readCachedOverview();
    try {
      final overview = await _repository.refreshOverview(
        requestId:
            'account-overview-${DateTime.now().toUtc().microsecondsSinceEpoch}',
      );
      state = AsyncData(overview);
    } catch (error, stackTrace) {
      if (cachedOverview != null) {
        state = AsyncData(cachedOverview);
      } else {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> clearCachedOverview() async {
    state = const AsyncData<AccountOverview?>(null);
    await _repository.clearCachedOverview();
  }
}
