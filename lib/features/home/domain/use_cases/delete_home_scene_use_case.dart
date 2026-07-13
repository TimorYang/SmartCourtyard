import '../repositories/home_scene_repository.dart';

class DeleteHomeSceneUseCase {
  const DeleteHomeSceneUseCase({required this.repository});

  final HomeSceneRepository repository;

  Future<void> call({required int sceneId, required String requestId}) {
    return repository.deleteScene(sceneId: sceneId, requestId: requestId);
  }
}
