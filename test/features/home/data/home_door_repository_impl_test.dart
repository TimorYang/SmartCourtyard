import 'package:dio/dio.dart';
import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/network_exception.dart';
import 'package:flinx/features/home/data/data_sources/home_door_remote_data_source.dart';
import 'package:flinx/features/home/data/dto/home_door_response_dto.dart';
import 'package:flinx/features/home/data/repositories/home_door_repository_impl.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps door dto to device summary', () async {
    final repository = HomeDoorRepositoryImpl(
      remoteDataSource: const _FakeHomeDoorRemoteDataSource([
        HomeDoorResponseDto(
          id: 12,
          name: 'Main Gate',
          sceneId: 7,
          onlineStatusLabel: '在线',
          doorStateLabel: '正在关门',
        ),
      ]),
      logger: const _NoopLogger(),
    );

    final doors = await repository.fetchDoors(
      sceneId: 7,
      requestId: 'home-doors-123',
    );

    expect(doors, hasLength(1));
    expect(doors.single.id, '12');
    expect(doors.single.name, 'Main Gate');
    expect(doors.single.sceneId, 7);
    expect(doors.single.onlineState, DeviceOnlineState.online);
    expect(doors.single.bleState, BleConnectionState.connected);
    expect(doors.single.doorState, DoorState.closing);
  });

  test('maps network failure to retryable app error', () async {
    final repository = HomeDoorRepositoryImpl(
      remoteDataSource: _FailingHomeDoorRemoteDataSource(
        HomeDoorRemoteException.fromNetwork(
          NetworkException.fromDio(
            DioException(
              requestOptions: RequestOptions(path: 'app/doors'),
              type: DioExceptionType.connectionError,
              error: 'offline',
            ),
          ),
        ),
      ),
      logger: const _NoopLogger(),
    );

    await expectLater(
      repository.fetchDoors(sceneId: 7, requestId: 'home-doors-123'),
      throwsA(
        isA<AppError>()
            .having(
              (error) => error.code,
              'code',
              AppErrorCode.networkUnavailable,
            )
            .having((error) => error.retryable, 'retryable', isTrue)
            .having((error) => error.requestId, 'requestId', 'home-doors-123'),
      ),
    );
  });
}

class _FakeHomeDoorRemoteDataSource implements HomeDoorRemoteDataSource {
  const _FakeHomeDoorRemoteDataSource(this.doors);

  final List<HomeDoorResponseDto> doors;

  @override
  Future<List<HomeDoorResponseDto>> fetchDoors({
    required int sceneId,
    required String requestId,
  }) async {
    return doors;
  }
}

class _FailingHomeDoorRemoteDataSource implements HomeDoorRemoteDataSource {
  const _FailingHomeDoorRemoteDataSource(this.error);

  final HomeDoorRemoteException error;

  @override
  Future<List<HomeDoorResponseDto>> fetchDoors({
    required int sceneId,
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
