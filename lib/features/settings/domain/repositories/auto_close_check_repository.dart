import '../entities/auto_close_check_result.dart';

abstract interface class AutoCloseCheckRepository {
  Future<AutoCloseCheckResult> checkAutoClose({
    required String doorId,
    required String deviceId,
    required String requestId,
  });
}
