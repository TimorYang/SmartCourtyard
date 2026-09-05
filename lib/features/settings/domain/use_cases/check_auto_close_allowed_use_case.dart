import '../entities/auto_close_check_result.dart';
import '../repositories/auto_close_check_repository.dart';

class CheckAutoCloseAllowedUseCase {
  const CheckAutoCloseAllowedUseCase(this._repository);

  final AutoCloseCheckRepository _repository;

  Future<AutoCloseCheckResult> call({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) {
    return _repository.checkAutoClose(
      doorId: doorId,
      deviceId: deviceId,
      requestId: requestId,
    );
  }
}
