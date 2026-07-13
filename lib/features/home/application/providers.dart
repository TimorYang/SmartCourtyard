import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/providers.dart';
import '../../../core/network/providers.dart';
import '../../../platform_bridge/hardware_models.dart';
import '../../../platform_bridge/providers.dart';
import '../data/data_sources/home_api.dart';
import '../data/data_sources/home_scene_remote_data_source.dart';
import '../data/repositories/home_scene_repository_impl.dart';
import '../domain/entities/home_scene.dart';
import '../domain/repositories/home_scene_repository.dart';
import '../domain/use_cases/create_home_scene_use_case.dart';
import '../domain/use_cases/fetch_home_scenes_use_case.dart';

final homeDevicesProvider = FutureProvider<List<DeviceSummary>>((ref) {
  final hardwareGateway = ref.watch(hardwareGatewayProvider);

  return hardwareGateway.readDevices();
});

final homeApiProvider = Provider<HomeApi>((ref) {
  return HomeApi(ref.watch(dioProvider));
});

final homeSceneRemoteDataSourceProvider = Provider<HomeSceneRemoteDataSource>(
  (ref) => HomeSceneRemoteDataSourceImpl(api: ref.watch(homeApiProvider)),
);

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

final createHomeSceneUseCaseProvider = Provider<CreateHomeSceneUseCase>((ref) {
  return CreateHomeSceneUseCase(
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
