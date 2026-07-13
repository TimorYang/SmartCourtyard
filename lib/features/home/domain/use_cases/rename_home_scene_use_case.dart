import '../repositories/home_scene_repository.dart';

class RenameHomeSceneUseCase {
  const RenameHomeSceneUseCase({required this.repository});

  final HomeSceneRepository repository;

  Future<void> call({
    required int sceneId,
    required String name,
    required String requestId,
  }) {
    return repository.renameScene(
      sceneId: sceneId,
      name: name,
      requestId: requestId,
    );
  }
}
