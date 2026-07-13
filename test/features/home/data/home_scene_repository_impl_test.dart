import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/network_exception.dart';
import 'package:flinx/features/home/data/data_sources/home_scene_remote_data_source.dart';
import 'package:flinx/features/home/data/dto/home_scene_response_dto.dart';
import 'package:flinx/features/home/data/repositories/home_scene_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps scene dto to domain entity', () async {
    final repository = HomeSceneRepositoryImpl(
      remoteDataSource: const _FakeHomeSceneRemoteDataSource([
        HomeSceneResponseDto(
          defaultScene: true,
          doorCount: 3,
          id: 10,
          name: 'Warehouse',
        ),
      ]),
      logger: const _NoopLogger(),
    );

    final scenes = await repository.fetchScenes(requestId: 'home-scenes-123');

    expect(scenes, hasLength(1));
    expect(scenes.single.id, 10);
    expect(scenes.single.name, 'Warehouse');
    expect(scenes.single.doorCount, 3);
    expect(scenes.single.isDefault, isTrue);
  });

  test('maps created scene dto to domain entity', () async {
    final repository = HomeSceneRepositoryImpl(
      remoteDataSource: const _FakeHomeSceneRemoteDataSource([
        HomeSceneResponseDto(
          defaultScene: false,
          doorCount: 0,
          id: 11,
          name: 'Garage',
        ),
      ]),
      logger: const _NoopLogger(),
    );

    final scene = await repository.createScene(
      name: 'Garage',
      requestId: 'home-create-scene-123',
    );

    expect(scene.id, 11);
    expect(scene.name, 'Garage');
    expect(scene.doorCount, 0);
    expect(scene.isDefault, isFalse);
  });

  test('maps network failure to retryable app error', () async {
    final repository = HomeSceneRepositoryImpl(
      remoteDataSource: _FailingHomeSceneRemoteDataSource(
        HomeSceneRemoteException.fromNetwork(
          NetworkException.fromDio(
            DioException(
              requestOptions: RequestOptions(path: 'app/scenes'),
              type: DioExceptionType.connectionError,
              error: 'offline',
            ),
          ),
        ),
      ),
      logger: const _NoopLogger(),
    );

    await expectLater(
      repository.fetchScenes(requestId: 'home-scenes-123'),
      throwsA(
        isA<AppError>()
            .having(
              (error) => error.code,
              'code',
              AppErrorCode.networkUnavailable,
            )
            .having((error) => error.retryable, 'retryable', isTrue)
            .having((error) => error.requestId, 'requestId', 'home-scenes-123'),
      ),
    );
  });
}

class _FakeHomeSceneRemoteDataSource implements HomeSceneRemoteDataSource {
  const _FakeHomeSceneRemoteDataSource(this.scenes);

  final List<HomeSceneResponseDto> scenes;

  @override
  Future<List<HomeSceneResponseDto>> fetchScenes({
    required String requestId,
  }) async {
    return scenes;
  }

  @override
  Future<HomeSceneResponseDto> createScene({
    required String name,
    required String requestId,
  }) async {
    return scenes.single;
  }

  @override
  Future<void> deleteScene({
    required int sceneId,
    required String requestId,
  }) async {}

  @override
  Future<void> renameScene({
    required int sceneId,
    required String name,
    required String requestId,
  }) async {}
}

class _FailingHomeSceneRemoteDataSource implements HomeSceneRemoteDataSource {
  const _FailingHomeSceneRemoteDataSource(this.error);

  final HomeSceneRemoteException error;

  @override
  Future<List<HomeSceneResponseDto>> fetchScenes({required String requestId}) {
    throw error;
  }

  @override
  Future<HomeSceneResponseDto> createScene({
    required String name,
    required String requestId,
  }) {
    throw error;
  }

  @override
  Future<void> deleteScene({required int sceneId, required String requestId}) {
    throw error;
  }

  @override
  Future<void> renameScene({
    required int sceneId,
    required String name,
    required String requestId,
  }) {
    throw error;
  }
}

class _NoopLogger implements AppLogger {
  const _NoopLogger();

  @override
  void error(
    String message, {
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void info(
    String message, {
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void warning(
    String message, {
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}
}
