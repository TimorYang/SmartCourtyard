import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/providers.dart';
import '../../../core/network/providers.dart';
import '../../../platform_bridge/hardware_models.dart';
import '../../auth/application/providers.dart';
import '../data/data_sources/home_api.dart';
import '../data/data_sources/door_share_remote_data_source.dart';
import '../data/repositories/door_share_repository_impl.dart';
import '../data/data_sources/home_door_remote_data_source.dart';
import '../data/data_sources/home_scene_remote_data_source.dart';
import '../data/repositories/home_door_repository_impl.dart';
import '../data/repositories/home_scene_repository_impl.dart';
import '../domain/entities/home_scene.dart';
import '../domain/repositories/door_share_repository.dart';
import '../domain/repositories/home_door_repository.dart';
import '../domain/repositories/home_scene_repository.dart';
import '../domain/use_cases/create_home_scene_use_case.dart';
import '../domain/use_cases/delete_home_scene_use_case.dart';
import '../domain/use_cases/create_door_share_use_case.dart';
import '../domain/use_cases/fetch_door_share_capabilities_use_case.dart';
import '../domain/use_cases/fetch_home_doors_use_case.dart';
import '../domain/use_cases/fetch_home_scenes_use_case.dart';
import '../domain/use_cases/move_home_door_to_scene_use_case.dart';
import '../domain/use_cases/rename_home_scene_use_case.dart';
import '../domain/use_cases/rename_home_door_use_case.dart';
import '../domain/use_cases/reset_home_door_cover_use_case.dart';
import '../domain/use_cases/top_home_door_use_case.dart';
import '../domain/use_cases/unbind_home_door_use_case.dart';
import '../domain/use_cases/update_door_share_use_case.dart';

final homeApiProvider = Provider<HomeApi>((ref) {
  return HomeApi(ref.watch(dioProvider));
});

final homeDoorRemoteDataSourceProvider = Provider<HomeDoorRemoteDataSource>(
  (ref) => HomeDoorRemoteDataSourceImpl(api: ref.watch(homeApiProvider)),
);

final homeSceneRemoteDataSourceProvider = Provider<HomeSceneRemoteDataSource>(
  (ref) => HomeSceneRemoteDataSourceImpl(api: ref.watch(homeApiProvider)),
);

final doorShareRemoteDataSourceProvider = Provider<DoorShareRemoteDataSource>(
  (ref) => DoorShareRemoteDataSourceImpl(api: ref.watch(homeApiProvider)),
);

final doorShareRepositoryProvider = Provider<DoorShareRepository>(
  (ref) => DoorShareRepositoryImpl(
    remoteDataSource: ref.watch(doorShareRemoteDataSourceProvider),
    logger: ref.watch(appLoggerProvider),
  ),
);

final fetchDoorShareCapabilitiesUseCaseProvider =
    Provider<FetchDoorShareCapabilitiesUseCase>(
      (ref) => FetchDoorShareCapabilitiesUseCase(
        repository: ref.watch(doorShareRepositoryProvider),
      ),
    );

final createDoorShareUseCaseProvider = Provider<CreateDoorShareUseCase>(
  (ref) => CreateDoorShareUseCase(
    repository: ref.watch(doorShareRepositoryProvider),
  ),
);

final updateDoorShareUseCaseProvider = Provider<UpdateDoorShareUseCase>(
  (ref) => UpdateDoorShareUseCase(
    repository: ref.watch(doorShareRepositoryProvider),
  ),
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

final moveHomeDoorToSceneUseCaseProvider = Provider<MoveHomeDoorToSceneUseCase>(
  (ref) {
    return MoveHomeDoorToSceneUseCase(
      repository: ref.watch(homeDoorRepositoryProvider),
    );
  },
);

final unbindHomeDoorUseCaseProvider = Provider<UnbindHomeDoorUseCase>((ref) {
  return UnbindHomeDoorUseCase(
    repository: ref.watch(homeDoorRepositoryProvider),
  );
});

final resetHomeDoorCoverUseCaseProvider = Provider<ResetHomeDoorCoverUseCase>(
  (ref) => ResetHomeDoorCoverUseCase(
    repository: ref.watch(homeDoorRepositoryProvider),
  ),
);

final renameHomeDoorUseCaseProvider = Provider<RenameHomeDoorUseCase>(
  (ref) =>
      RenameHomeDoorUseCase(repository: ref.watch(homeDoorRepositoryProvider)),
);

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

final homeScenesProvider = FutureProvider<List<HomeScene>>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (!session.isAuthenticated || session.userId?.isEmpty != false) {
    return const <HomeScene>[];
  }
  final useCase = ref.watch(fetchHomeScenesUseCaseProvider);
  return useCase(
    requestId:
        'home-fetch-scenes-${DateTime.now().toUtc().microsecondsSinceEpoch}',
  );
});

final homeDoorsBySceneProvider = FutureProvider.family<List<DeviceSummary>, int>((
  ref,
  sceneId,
) async {
  final session = await ref.watch(authSessionProvider.future);
  if (!session.isAuthenticated || session.userId?.isEmpty != false) {
    return const <DeviceSummary>[];
  }
  final useCase = ref.watch(fetchHomeDoorsUseCaseProvider);
  return useCase(
    sceneId: sceneId,
    requestId:
        'home-fetch-doors-$sceneId-${DateTime.now().toUtc().microsecondsSinceEpoch}',
  );
});

final homeDevicesProvider = FutureProvider<List<DeviceSummary>>((ref) async {
  final scenes = await ref.watch(homeScenesProvider.future);
  if (scenes.isEmpty) return const <DeviceSummary>[];
  final results = await Future.wait([
    for (final scene in scenes)
      ref.watch(homeDoorsBySceneProvider(scene.id).future),
  ]);
  return [for (final doors in results) ...doors];
});
