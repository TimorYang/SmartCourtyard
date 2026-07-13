import '../entities/home_scene.dart';
import '../repositories/home_scene_repository.dart';

class CreateHomeSceneUseCase {
  const CreateHomeSceneUseCase({required this.repository});

  final HomeSceneRepository repository;

  Future<HomeScene> call({required String name, required String requestId}) {
    return repository.createScene(name: name, requestId: requestId);
  }
}
