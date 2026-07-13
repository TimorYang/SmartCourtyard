import '../../../../platform_bridge/hardware_models.dart';
import '../repositories/home_door_repository.dart';

class FetchHomeDoorsUseCase {
  const FetchHomeDoorsUseCase({required this.repository});

  final HomeDoorRepository repository;

  Future<List<DeviceSummary>> call({
    required int sceneId,
    required String requestId,
  }) {
    return repository.fetchDoors(sceneId: sceneId, requestId: requestId);
  }
}
