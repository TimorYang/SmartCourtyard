import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../domain/repositories/home_door_repository.dart';
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
    );
  }

  DeviceOnlineState _onlineState() {
    final label = onlineStatusLabel?.trim().toLowerCase() ?? '';
    if (label.contains('online') || label.contains('在线')) {
      return DeviceOnlineState.online;
    }
    if (label.contains('offline') || label.contains('离线')) {
      return DeviceOnlineState.offline;
    }
    return switch (onlineStatus) {
      1 => DeviceOnlineState.online,
      0 => DeviceOnlineState.offline,
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
