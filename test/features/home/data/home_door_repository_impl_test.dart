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
      remoteDataSource: _FakeHomeDoorRemoteDataSource([
        HomeDoorResponseDto(
          id: 12,
          name: 'Main Gate',
          sceneId: 7,
          onlineStatus: 1,
          onlineStatusLabel: '在线',
          doorStateLabel: '正在关门',
          doorType: 3,
          coverFileId: 30001,
          shareStatus: 2,
          shareStatusLabel: 'Sharing',
          hasBoundDevices: true,
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
    expect(doors.single.doorType, DoorType.swing);
    expect(doors.single.coverFileId, 30001);
    expect(doors.single.shareStatus, 2);
    expect(doors.single.shareStatusLabel, 'Sharing');
    expect(doors.single.hasBoundDevices, isTrue);
  });

  for (final fixture in [
    (wireValue: 0, expected: DeviceOnlineState.offline),
    (wireValue: 1, expected: DeviceOnlineState.online),
    (wireValue: 2, expected: DeviceOnlineState.unknown),
  ]) {
    test(
      'maps onlineStatus ${fixture.wireValue} to ${fixture.expected.name}',
      () async {
        final repository = HomeDoorRepositoryImpl(
          remoteDataSource: _FakeHomeDoorRemoteDataSource([
            HomeDoorResponseDto(
              id: 12,
              name: 'Main Gate',
              sceneId: 7,
              onlineStatus: fixture.wireValue,
              onlineStatusLabel: '在线',
            ),
          ]),
          logger: const _NoopLogger(),
        );

        final doors = await repository.fetchDoors(
          sceneId: 7,
          requestId: 'home-doors-123',
        );

        expect(doors.single.onlineState, fixture.expected);
      },
    );
  }

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

  test('tops a door', () async {
    final dataSource = _FakeHomeDoorRemoteDataSource(const []);
    final repository = HomeDoorRepositoryImpl(
      remoteDataSource: dataSource,
      logger: const _NoopLogger(),
    );

    await repository.topDoor(doorId: 12, requestId: 'home-top-door-123');

    expect(dataSource.topDoorId, 12);
    expect(dataSource.topRequestId, 'home-top-door-123');
  });

  test('unbinds a door', () async {
    final dataSource = _FakeHomeDoorRemoteDataSource(const []);
    final repository = HomeDoorRepositoryImpl(
      remoteDataSource: dataSource,
      logger: const _NoopLogger(),
    );

    await repository.unbindDoor(doorId: 12, requestId: 'home-unbind-door-123');

    expect(dataSource.unbindDoorId, 12);
    expect(dataSource.unbindRequestId, 'home-unbind-door-123');
  });

  test('resets a door cover', () async {
    final dataSource = _FakeHomeDoorRemoteDataSource(const []);
    final repository = HomeDoorRepositoryImpl(
      remoteDataSource: dataSource,
      logger: const _NoopLogger(),
    );

    await repository.resetDoorCover(
      doorId: 12,
      requestId: 'home-reset-door-cover-123',
    );

    expect(dataSource.resetDoorCoverId, 12);
    expect(dataSource.resetDoorCoverRequestId, 'home-reset-door-cover-123');
  });

  test('renames a door', () async {
    final dataSource = _FakeHomeDoorRemoteDataSource(const []);
    final repository = HomeDoorRepositoryImpl(
      remoteDataSource: dataSource,
      logger: const _NoopLogger(),
    );

    await repository.renameDoor(
      doorId: 12,
      name: 'Garage Door',
      requestId: 'home-rename-door-123',
    );

    expect(dataSource.renameDoorId, 12);
    expect(dataSource.renameDoorName, 'Garage Door');
    expect(dataSource.renameDoorRequestId, 'home-rename-door-123');
  });

  test('moves a door to a scene', () async {
    final dataSource = _FakeHomeDoorRemoteDataSource(const []);
    final repository = HomeDoorRepositoryImpl(
      remoteDataSource: dataSource,
      logger: const _NoopLogger(),
    );

    await repository.moveDoorToScene(
      doorId: 12,
      sceneId: 8,
      requestId: 'home-move-door-12-to-8',
    );

    expect(dataSource.moveDoorId, 12);
    expect(dataSource.moveSceneId, 8);
    expect(dataSource.moveRequestId, 'home-move-door-12-to-8');
  });
}

class _FakeHomeDoorRemoteDataSource implements HomeDoorRemoteDataSource {
  _FakeHomeDoorRemoteDataSource(this.doors);

  final List<HomeDoorResponseDto> doors;
  int? topDoorId;
  String? topRequestId;
  int? unbindDoorId;
  String? unbindRequestId;
  int? resetDoorCoverId;
  String? resetDoorCoverRequestId;
  int? renameDoorId;
  String? renameDoorName;
  String? renameDoorRequestId;
  int? moveDoorId;
  int? moveSceneId;
  String? moveRequestId;

  @override
  Future<void> topDoor({required int doorId, required String requestId}) async {
    topDoorId = doorId;
    topRequestId = requestId;
  }

  @override
  Future<void> unbindDoor({
    required int doorId,
    required String requestId,
  }) async {
    unbindDoorId = doorId;
    unbindRequestId = requestId;
  }

  @override
  Future<void> resetDoorCover({
    required int doorId,
    required String requestId,
  }) async {
    resetDoorCoverId = doorId;
    resetDoorCoverRequestId = requestId;
  }

  @override
  Future<void> renameDoor({
    required int doorId,
    required String name,
    required String requestId,
  }) async {
    renameDoorId = doorId;
    renameDoorName = name;
    renameDoorRequestId = requestId;
  }

  @override
  Future<void> moveDoorToScene({
    required int doorId,
    required int sceneId,
    required String requestId,
  }) async {
    moveDoorId = doorId;
    moveSceneId = sceneId;
    moveRequestId = requestId;
  }

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
  Future<void> topDoor({required int doorId, required String requestId}) {
    throw error;
  }

  @override
  Future<void> unbindDoor({required int doorId, required String requestId}) {
    throw error;
  }

  @override
  Future<void> resetDoorCover({
    required int doorId,
    required String requestId,
  }) {
    throw error;
  }

  @override
  Future<void> renameDoor({
    required int doorId,
    required String name,
    required String requestId,
  }) {
    throw error;
  }

  @override
  Future<void> moveDoorToScene({
    required int doorId,
    required int sceneId,
    required String requestId,
  }) {
    throw error;
  }

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
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void info(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void warning(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}
}
