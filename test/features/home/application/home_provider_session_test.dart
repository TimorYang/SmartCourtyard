import 'dart:async';

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

  test(
    'disposes account A home data before account B starts loading',
    () async {
      final sceneRepository = _AccountSwitchHomeSceneRepository();
      final doorRepository = _CountingHomeDoorRepository();
      final container = ProviderContainer(
        overrides: [
          fetchHomeScenesUseCaseProvider.overrideWithValue(
            FetchHomeScenesUseCase(repository: sceneRepository),
          ),
          fetchHomeDoorsUseCaseProvider.overrideWithValue(
            FetchHomeDoorsUseCase(repository: doorRepository),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        homeDevicesProvider,
        (_, _) {},
        fireImmediately: true,
      );

      container
          .read(activeAuthSessionProvider.notifier)
          .markAuthenticated(userId: 'user-a');
      await container.read(homeDevicesProvider.future);
      expect(doorRepository.fetchCountByScene, {33: 1, 35: 1});

      container.read(activeAuthSessionProvider.notifier).clear();
      container.read(homeDeviceListsInvalidatorProvider)();
      subscription.close();
      await container.pump();

      expect(container.exists(homeScenesProvider), isFalse);
      expect(container.exists(homeDevicesProvider), isFalse);
      expect(container.exists(homeDoorsBySceneProvider(33)), isFalse);
      expect(container.exists(homeDoorsBySceneProvider(35)), isFalse);

      container
          .read(activeAuthSessionProvider.notifier)
          .markAuthenticated(userId: 'user-b');
      final userBSubscription = container.listen(
        homeDevicesProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(userBSubscription.close);
      final userBDevices = container.read(homeDevicesProvider.future);
      await container.pump();
      expect(doorRepository.fetchCountByScene, {33: 1, 35: 1});

      sceneRepository.completeUserBScenes();
      await userBDevices;
      expect(doorRepository.fetchCountByScene, {33: 1, 35: 1, 4: 1, 8: 1});
    },
  );

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

  test('home device list invalidator refreshes every scene cache', () async {
    final doorRepository = _CountingHomeDoorRepository();
    var sceneFetchCount = 0;
    final container = ProviderContainer(
      overrides: [
        homeScenesProvider.overrideWith((ref) async {
          sceneFetchCount++;
          return const [
            HomeScene(id: 1, name: 'Home', doorCount: 0, isDefault: true),
            HomeScene(id: 2, name: 'Garage', doorCount: 0, isDefault: false),
          ];
        }),
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
    expect(sceneFetchCount, 1);

    container.read(homeDeviceListsInvalidatorProvider)();
    await container.read(homeDevicesProvider.future);

    expect(doorRepository.fetchCountByScene, {1: 2, 2: 2});
    expect(sceneFetchCount, 2);
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

class _AccountSwitchHomeSceneRepository implements HomeSceneRepository {
  final _userBScenes = Completer<List<HomeScene>>();
  var fetchCount = 0;

  void completeUserBScenes() {
    _userBScenes.complete(const [
      HomeScene(id: 4, name: 'B Home', doorCount: 1, isDefault: true),
      HomeScene(id: 8, name: 'B Garage', doorCount: 1, isDefault: false),
    ]);
  }

  @override
  Future<List<HomeScene>> fetchScenes({required String requestId}) {
    fetchCount += 1;
    if (fetchCount == 1) {
      return Future.value(const [
        HomeScene(id: 33, name: 'A Home', doorCount: 1, isDefault: true),
        HomeScene(id: 35, name: 'A Garage', doorCount: 1, isDefault: false),
      ]);
    }
    return _userBScenes.future;
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
