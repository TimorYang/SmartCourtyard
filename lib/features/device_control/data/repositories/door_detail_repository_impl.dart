import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../domain/entities/door_detail.dart';
import '../../domain/repositories/door_detail_repository.dart';
import '../data_sources/door_detail_remote_data_source.dart';
import '../dto/door_detail_response_dto.dart';

class DoorDetailRepositoryImpl implements DoorDetailRepository {
  const DoorDetailRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final DoorDetailRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) async {
    final parsedDoorId = int.tryParse(doorId.trim());
    if (parsedDoorId == null) {
      throw AppError(
        code: AppErrorCode.unknown,
        messageKey: 'door_detail_invalid_door_id',
        requestId: requestId,
        deviceId: doorId,
      );
    }

    try {
      final dto = await remoteDataSource.fetchDoorDetail(
        doorId: parsedDoorId,
        requestId: requestId,
      );
      return dto.toDomain();
    } on DoorDetailRemoteException catch (error, stackTrace) {
      final appError = _mapError(error, requestId, doorId);
      logger.error(
        'Failed to fetch door detail',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'errorKind': error.kind.name},
      );
      throw appError;
    }
  }

  AppError _mapError(
    DoorDetailRemoteException error,
    String requestId,
    String doorId,
  ) {
    if (error.kind == DoorDetailRemoteErrorKind.network) {
      return AppError(
        code: AppErrorCode.networkUnavailable,
        messageKey: 'door_detail_network_unavailable',
        action: AppErrorAction.retry,
        requestId: requestId,
        deviceId: doorId,
        retryable: true,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'door_detail_invalid_response',
      action: AppErrorAction.retry,
      requestId: requestId,
      deviceId: doorId,
      retryable: true,
    );
  }
}

extension DoorDetailResponseDtoMapper on DoorDetailResponseDto {
  DoorDetail toDomain() {
    return DoorDetail(
      id: id.toString(),
      name: name.trim().isEmpty ? 'Garage door' : name.trim(),
      doorType: doorType,
      doorTypeLabel: doorTypeLabel,
      controlMode: controlMode,
      controlModeLabel: controlModeLabel,
      onlineStatus: onlineStatus,
      onlineStatusLabel: onlineStatusLabel,
      doorState: _doorState(),
      doorStateLabel: _doorStateLabel(),
      positionPercent: positionPercent,
      coverFileId: coverFileId,
      operatedCycles: operatedCycles ?? 0,
      remainingCycles: remainingCycles ?? 0,
      associatedDevices: associatedDevices
          .map(
            (device) => DoorAssociatedDevice(
              deviceType: device.deviceType?.trim() ?? '',
              deviceTypeLabel: device.deviceTypeLabel?.trim(),
              associated: device.associated,
              primaryControl: device.primaryControl,
              bleName: device.bleName?.trim() ?? '',
              bleUuid: device.bleUuid,
              bleMac: device.bleMac,
              capabilities: device.capabilities,
            ),
          )
          .toList(),
    );
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
        label.contains('已关')) {
      return DoorState.closed;
    }
    if (label.contains('open') ||
        label.contains('开启') ||
        label.contains('已开')) {
      return DoorState.open;
    }
    return switch (doorState) {
      1 => DoorState.open,
      2 => DoorState.closed,
      3 => DoorState.opening,
      4 => DoorState.closing,
      5 => DoorState.stopped,
      _ => DoorState.unknown,
    };
  }

  String _doorStateLabel() {
    final label = doorStateLabel?.trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }
    return switch (_doorState()) {
      DoorState.open => 'Open',
      DoorState.opening => 'Opening',
      DoorState.stopped => 'Stopped',
      DoorState.closing => 'Closing',
      DoorState.closed => 'Closed',
      DoorState.unknown => 'Unknown',
    };
  }
}
