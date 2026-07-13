import '../entities/home_scene.dart';
import '../repositories/home_scene_repository.dart';

class FetchHomeScenesUseCase {
  const FetchHomeScenesUseCase({required this.repository});

  final HomeSceneRepository repository;

  Future<List<HomeScene>> call({required String requestId}) {
    return repository.fetchScenes(requestId: requestId);
  }
}
