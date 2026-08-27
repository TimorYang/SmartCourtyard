import '../entities/upgrade_check.dart';
import '../repositories/upgrade_repository.dart';

class FetchFirmwareUpgradesUseCase {
  const FetchFirmwareUpgradesUseCase(this._repository);

  final UpgradeRepository _repository;

  Future<List<FirmwareUpgradeDoor>> call({required String requestId}) {
    return _repository.fetchFirmwareUpgrades(requestId: requestId);
  }
}
