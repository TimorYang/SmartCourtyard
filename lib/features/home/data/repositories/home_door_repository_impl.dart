import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../domain/repositories/home_door_repository.dart';
import '../../domain/entities/home_door_cover_image.dart';
import '../data_sources/home_door_remote_data_source.dart';
import '../dto/home_door_response_dto.dart';

class HomeDoorRepositoryImpl implements HomeDoorRepository {
  const HomeDoorRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final HomeDoorRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<List<DeviceSummary>> fetchDoors({
    required int sceneId,
    required String requestId,
  }) async {
    try {
      final doors = await remoteDataSource.fetchDoors(
        sceneId: sceneId,
        requestId: requestId,
      );
      logger.info(
        'Fetched home doors.',
        requestId: requestId,
        context: {'sceneId': sceneId, 'doorCount': doors.length},
      );
      return doors.map((door) => door.toDomain()).toList(growable: false);
    } on HomeDoorRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to fetch home doors.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'sceneId': sceneId, 'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<void> topDoor({required int doorId, required String requestId}) async {
    try {
      await remoteDataSource.topDoor(doorId: doorId, requestId: requestId);
      logger.info(
        'Topped home door.',
        requestId: requestId,
        context: {'doorId': doorId},
      );
    } on HomeDoorRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to top home door.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<void> unbindDoor({
    required int doorId,
    required String requestId,
  }) async {
    try {
      await remoteDataSource.unbindDoor(doorId: doorId, requestId: requestId);
      logger.info(
        'Unbound home door.',
        requestId: requestId,
        context: {'doorId': doorId},
      );
    } on HomeDoorRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to unbind home door.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<void> resetDoorCover({
    required int doorId,
    required String requestId,
  }) async {
    try {
      await remoteDataSource.resetDoorCover(
        doorId: doorId,
        requestId: requestId,
      );
      logger.info(
        'Reset home door cover.',
        requestId: requestId,
        context: {'doorId': doorId},
      );
    } on HomeDoorRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to reset home door cover.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<void> updateDoorCover({
    required int doorId,
    required HomeDoorCoverImage image,
    required String requestId,
  }) async {
    try {
      await remoteDataSource.updateDoorCover(
        doorId: doorId,
        image: image,
        requestId: requestId,
      );
      logger.info(
        'Updated home door cover.',
        requestId: requestId,
        context: {'doorId': doorId},
      );
    } on HomeDoorRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to update home door cover.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<void> renameDoor({
    required int doorId,
    required String name,
    required String requestId,
  }) async {
    try {
      await remoteDataSource.renameDoor(
        doorId: doorId,
        name: name,
        requestId: requestId,
      );
      logger.info(
        'Renamed home door.',
        requestId: requestId,
        context: {'doorId': doorId},
      );
    } on HomeDoorRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to rename home door.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<void> moveDoorToScene({
    required int doorId,
    required int sceneId,
    required String requestId,
  }) async {
    try {
      await remoteDataSource.moveDoorToScene(
        doorId: doorId,
        sceneId: sceneId,
        requestId: requestId,
      );
      logger.info(
        'Moved home door to scene.',
        requestId: requestId,
        context: {'doorId': doorId, 'sceneId': sceneId},
      );
    } on HomeDoorRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to move home door to scene.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'doorId': doorId,
          'sceneId': sceneId,
          'statusCode': error.statusCode,
        },
      );
      throw _mapError(error, requestId);
    }
  }

  AppError _mapError(HomeDoorRemoteException error, String requestId) {
    if (error.kind == HomeDoorRemoteErrorKind.network) {
      return AppError(
        code: AppErrorCode.networkUnavailable,
        messageKey: 'home.doors.networkUnavailable',
        action: AppErrorAction.retry,
        requestId: requestId,
        retryable: true,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'home.doors.failed',
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }
}

extension HomeDoorResponseDtoMapper on HomeDoorResponseDto {
  DeviceSummary toDomain() {
    return DeviceSummary(
      id: id.toString(),
      name: name.trim().isEmpty ? 'Door $id' : name.trim(),
      onlineState: _onlineState(),
      bleState: _onlineState() == DeviceOnlineState.online
          ? BleConnectionState.connected
          : BleConnectionState.disconnected,
      doorState: _doorState(),
      cycleCount: 0,
      remainingLifePercent: 100,
      sceneId: sceneId,
      doorType: DoorType.fromWireValue(doorType),
      coverFileId: coverFileId,
      shareStatus: shareStatus,
      shareStatusLabel: shareStatusLabel,
      hasBoundDevices: hasBoundDevices,
    );
  }

  DeviceOnlineState _onlineState() {
    return switch (onlineStatus) {
      1 => DeviceOnlineState.online,
      0 => DeviceOnlineState.offline,
      2 => DeviceOnlineState.unknown,
      _ => DeviceOnlineState.unknown,
    };
  }

  DoorState _doorState() {
    final label = doorStateLabel?.trim().toLowerCase() ?? '';
    if (label.contains('opening') || label.contains('正在开')) {
      return DoorState.opening;
    }
    if (label.contains('closing') || label.contains('正在关')) {
      return DoorState.closing;
    }
    if (label.contains('stopped') ||
        label.contains('stop') ||
        label.contains('停止')) {
      return DoorState.stopped;
    }
    if (label.contains('closed') ||
        label.contains('关闭') ||
        label.contains('关门') ||
        label.contains('已关')) {
      return DoorState.closed;
    }
    if (label.contains('open') ||
        label.contains('开启') ||
        label.contains('打开') ||
        label.contains('已开')) {
      return DoorState.open;
    }
    return switch (doorState) {
      1 => DoorState.open,
      2 => DoorState.opening,
      3 => DoorState.stopped,
      4 => DoorState.closing,
      5 => DoorState.closed,
      _ => DoorState.unknown,
    };
  }
}
