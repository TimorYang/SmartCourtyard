import '../entities/door_setting_snapshot.dart';
import '../repositories/door_settings_repository.dart';

class FetchDoorSettingsUseCase {
  const FetchDoorSettingsUseCase(this._repository);

  final DoorSettingsRepository _repository;

  Future<List<DoorSettingSnapshot>> call({
    required String doorId,
    required String requestId,
  }) => _repository.fetchSettings(doorId: doorId, requestId: requestId);
}
