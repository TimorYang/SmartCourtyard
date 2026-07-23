import '../entities/security_balance_refresh_result.dart';

abstract interface class SecurityBalanceRefreshRepository {
  Future<SecurityBalanceRefreshResult> refreshBalance({
    required String doorId,
    required String requestId,
  });
}
