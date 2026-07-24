import '../repositories/home_door_repository.dart';

class MoveHomeDoorToSceneUseCase {
  const MoveHomeDoorToSceneUseCase({required this.repository});

  final HomeDoorRepository repository;

  Future<void> call({
    required int doorId,
    required int sceneId,
    required String requestId,
  }) {
    return repository.moveDoorToScene(
      doorId: doorId,
      sceneId: sceneId,
      requestId: requestId,
    );
  }
}
