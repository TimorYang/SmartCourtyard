import '../repositories/security_balance_refresh_repository.dart';
import '../entities/security_balance_refresh_result.dart';

class RefreshSecurityBalanceUseCase {
  const RefreshSecurityBalanceUseCase({required this.repository});

  final SecurityBalanceRefreshRepository repository;

  Future<SecurityBalanceRefreshResult> call({
    required String doorId,
    required String requestId,
  }) {
    return repository.refreshBalance(doorId: doorId, requestId: requestId);
  }
}
