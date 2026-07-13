import '../entities/home_scene.dart';

abstract interface class HomeSceneRepository {
  Future<List<HomeScene>> fetchScenes({required String requestId});

  Future<HomeScene> createScene({
    required String name,
    required String requestId,
  });

  Future<void> deleteScene({required int sceneId, required String requestId});

  Future<void> renameScene({
    required int sceneId,
    required String name,
    required String requestId,
  });
}
