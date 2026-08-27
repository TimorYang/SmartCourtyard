import '../entities/upgrade_check.dart';
import '../repositories/upgrade_repository.dart';

class CheckAppReleaseUseCase {
  const CheckAppReleaseUseCase(this._repository);

  final UpgradeRepository _repository;

  Future<AppReleaseUpdate> call({required String requestId}) {
    return _repository.checkAppRelease(requestId: requestId);
  }
}
