import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/providers.dart';
import '../../../core/network/providers.dart';
import '../../../platform_bridge/hardware_models.dart';
import '../data/data_sources/home_api.dart';
import '../data/data_sources/home_door_remote_data_source.dart';
import '../data/data_sources/home_scene_remote_data_source.dart';
import '../data/repositories/home_door_repository_impl.dart';
import '../data/repositories/home_scene_repository_impl.dart';
import '../domain/entities/home_scene.dart';
import '../domain/repositories/home_door_repository.dart';
import '../domain/repositories/home_scene_repository.dart';
import '../domain/use_cases/create_home_scene_use_case.dart';
import '../domain/use_cases/delete_home_scene_use_case.dart';
import '../domain/use_cases/fetch_home_doors_use_case.dart';
import '../domain/use_cases/fetch_home_scenes_use_case.dart';
import '../domain/use_cases/rename_home_scene_use_case.dart';
import '../domain/use_cases/top_home_door_use_case.dart';

final homeApiProvider = Provider<HomeApi>((ref) {
  return HomeApi(ref.watch(dioProvider));
});

final homeDoorRemoteDataSourceProvider = Provider<HomeDoorRemoteDataSource>(
  (ref) => HomeDoorRemoteDataSourceImpl(api: ref.watch(homeApiProvider)),
);

final homeSceneRemoteDataSourceProvider = Provider<HomeSceneRemoteDataSource>(
  (ref) => HomeSceneRemoteDataSourceImpl(api: ref.watch(homeApiProvider)),
);

final homeDoorRepositoryProvider = Provider<HomeDoorRepository>((ref) {
  return HomeDoorRepositoryImpl(
    remoteDataSource: ref.watch(homeDoorRemoteDataSourceProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final homeSceneRepositoryProvider = Provider<HomeSceneRepository>((ref) {
  return HomeSceneRepositoryImpl(
    remoteDataSource: ref.watch(homeSceneRemoteDataSourceProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final fetchHomeScenesUseCaseProvider = Provider<FetchHomeScenesUseCase>((ref) {
  return FetchHomeScenesUseCase(
    repository: ref.watch(homeSceneRepositoryProvider),
  );
});

final fetchHomeDoorsUseCaseProvider = Provider<FetchHomeDoorsUseCase>((ref) {
  return FetchHomeDoorsUseCase(
    repository: ref.watch(homeDoorRepositoryProvider),
  );
});

final topHomeDoorUseCaseProvider = Provider<TopHomeDoorUseCase>((ref) {
  return TopHomeDoorUseCase(repository: ref.watch(homeDoorRepositoryProvider));
});

final createHomeSceneUseCaseProvider = Provider<CreateHomeSceneUseCase>((ref) {
  return CreateHomeSceneUseCase(
    repository: ref.watch(homeSceneRepositoryProvider),
  );
});

final deleteHomeSceneUseCaseProvider = Provider<DeleteHomeSceneUseCase>((ref) {
  return DeleteHomeSceneUseCase(
    repository: ref.watch(homeSceneRepositoryProvider),
  );
});

final renameHomeSceneUseCaseProvider = Provider<RenameHomeSceneUseCase>((ref) {
  return RenameHomeSceneUseCase(
    repository: ref.watch(homeSceneRepositoryProvider),
  );
});

final homeScenesProvider = FutureProvider<List<HomeScene>>((ref) {
  final useCase = ref.watch(fetchHomeScenesUseCaseProvider);
  return useCase(
    requestId:
        'home-fetch-scenes-${DateTime.now().toUtc().microsecondsSinceEpoch}',
  );
});

final homeDevicesProvider = FutureProvider<List<DeviceSummary>>((ref) async {
  final scenes = await ref.watch(homeScenesProvider.future);
  if (scenes.isEmpty) {
    return const <DeviceSummary>[];
  }

  final useCase = ref.watch(fetchHomeDoorsUseCaseProvider);
  final now = DateTime.now().toUtc().microsecondsSinceEpoch;
  final results = await Future.wait([
    for (final scene in scenes)
      useCase(
        sceneId: scene.id,
        requestId: 'home-fetch-doors-${scene.id}-$now',
      ),
  ]);

  return [for (final doors in results) ...doors];
});
