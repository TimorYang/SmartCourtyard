import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/home_scene.dart';
import '../../domain/repositories/home_scene_repository.dart';
import '../data_sources/home_scene_remote_data_source.dart';
import '../dto/home_scene_response_dto.dart';

class HomeSceneRepositoryImpl implements HomeSceneRepository {
  const HomeSceneRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final HomeSceneRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<List<HomeScene>> fetchScenes({required String requestId}) async {
    try {
      final scenes = await remoteDataSource.fetchScenes(requestId: requestId);
      logger.info(
        'Fetched home scenes.',
        requestId: requestId,
        context: {'sceneCount': scenes.length},
      );
      return scenes.map((scene) => scene.toDomain()).toList(growable: false);
    } on HomeSceneRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to fetch home scenes.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<HomeScene> createScene({
    required String name,
    required String requestId,
  }) async {
    try {
      final scene = await remoteDataSource.createScene(
        name: name,
        requestId: requestId,
      );
      logger.info(
        'Created home scene.',
        requestId: requestId,
        context: {'sceneId': scene.id},
      );
      return scene.toDomain();
    } on HomeSceneRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to create home scene.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<void> deleteScene({
    required int sceneId,
    required String requestId,
  }) async {
    try {
      await remoteDataSource.deleteScene(
        sceneId: sceneId,
        requestId: requestId,
      );
      logger.info(
        'Deleted home scene.',
        requestId: requestId,
        context: {'sceneId': sceneId},
      );
    } on HomeSceneRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to delete home scene.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'sceneId': sceneId, 'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<void> renameScene({
    required int sceneId,
    required String name,
    required String requestId,
  }) async {
    try {
      await remoteDataSource.renameScene(
        sceneId: sceneId,
        name: name,
        requestId: requestId,
      );
      logger.info(
        'Renamed home scene.',
        requestId: requestId,
        context: {'sceneId': sceneId},
      );
    } on HomeSceneRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to rename home scene.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'sceneId': sceneId, 'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  AppError _mapError(HomeSceneRemoteException error, String requestId) {
    if (error.kind == HomeSceneRemoteErrorKind.network &&
        error.network != null) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'home.scenes.failed',
      businessCode: error.businessFailure?.code,
      businessMessageKey: error.businessFailure?.messageKey,
      userMessage: error.kind == HomeSceneRemoteErrorKind.businessFailure
          ? error.businessFailure?.message
          : null,
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }
}

extension HomeSceneResponseDtoMapper on HomeSceneResponseDto {
  HomeScene toDomain() {
    return HomeScene(
      id: id,
      name: name,
      doorCount: doorCount,
      isDefault: defaultScene,
    );
  }
}
