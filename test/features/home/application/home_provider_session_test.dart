import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/features/home/domain/entities/home_scene.dart';
import 'package:flinx/features/home/domain/entities/home_door_cover_image.dart';
import 'package:flinx/features/home/domain/repositories/home_scene_repository.dart';
import 'package:flinx/features/home/domain/repositories/home_door_repository.dart';
import 'package:flinx/features/home/domain/use_cases/fetch_home_doors_use_case.dart';
import 'package:flinx/features/home/domain/use_cases/fetch_home_scenes_use_case.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reloads home scenes when the authenticated user changes', () async {
    final repository = _SequencedHomeSceneRepository();
    final container = ProviderContainer(
      overrides: [
        fetchHomeScenesUseCaseProvider.overrideWithValue(
          FetchHomeScenesUseCase(repository: repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(activeAuthSessionProvider.notifier)
        .markAuthenticated(userId: 'user-a');
    final firstScenes = await container.read(homeScenesProvider.future);

    container.read(activeAuthSessionProvider.notifier).clear();
    container
        .read(activeAuthSessionProvider.notifier)
        .markAuthenticated(userId: 'user-b');
    final secondScenes = await container.read(homeScenesProvider.future);

    expect(firstScenes.single.name, 'A Home');
    expect(secondScenes.single.name, 'B Home');
    expect(repository.fetchCount, 2);
  });

  test('refreshing one scene reuses other scene door caches', () async {
    final doorRepository = _CountingHomeDoorRepository();
    final container = ProviderContainer(
      overrides: [
        homeScenesProvider.overrideWith(
          (ref) async => const [
            HomeScene(id: 1, name: 'Home', doorCount: 0, isDefault: true),
            HomeScene(id: 2, name: 'Garage', doorCount: 0, isDefault: false),
          ],
        ),
        fetchHomeDoorsUseCaseProvider.overrideWithValue(
          FetchHomeDoorsUseCase(repository: doorRepository),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(activeAuthSessionProvider.notifier)
        .markAuthenticated(userId: 'user-a');

    await container.read(homeDevicesProvider.future);
    expect(doorRepository.fetchCountByScene, {1: 1, 2: 1});

    container.invalidate(homeDoorsBySceneProvider(1));
    container.invalidate(homeDevicesProvider);
    await container.read(homeDevicesProvider.future);

    expect(doorRepository.fetchCountByScene, {1: 2, 2: 1});
  });
}

class _SequencedHomeSceneRepository implements HomeSceneRepository {
  var fetchCount = 0;

  @override
  Future<List<HomeScene>> fetchScenes({required String requestId}) async {
    fetchCount++;
    return [
      HomeScene(
        id: fetchCount,
        name: fetchCount == 1 ? 'A Home' : 'B Home',
        doorCount: 0,
        isDefault: true,
      ),
    ];
  }

  @override
  Future<HomeScene> createScene({
    required String name,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteScene({required int sceneId, required String requestId}) =>
      throw UnimplementedError();

  @override
  Future<void> renameScene({
    required int sceneId,
    required String name,
    required String requestId,
  }) => throw UnimplementedError();
}

class _CountingHomeDoorRepository implements HomeDoorRepository {
  final fetchCountByScene = <int, int>{};

  @override
  Future<List<DeviceSummary>> fetchDoors({
    required int sceneId,
    required String requestId,
  }) async {
    fetchCountByScene.update(sceneId, (count) => count + 1, ifAbsent: () => 1);
    return const [];
  }

  @override
  Future<void> moveDoorToScene({
    required int doorId,
    required int sceneId,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<void> renameDoor({
    required int doorId,
    required String name,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<void> resetDoorCover({
    required int doorId,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<void> updateDoorCover({
    required int doorId,
    required HomeDoorCoverImage image,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<void> topDoor({required int doorId, required String requestId}) =>
      throw UnimplementedError();

  @override
  Future<void> unbindDoor({required int doorId, required String requestId}) =>
      throw UnimplementedError();
}
