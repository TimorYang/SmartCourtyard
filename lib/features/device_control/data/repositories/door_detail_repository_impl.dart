import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../domain/entities/door_detail.dart';
import '../../domain/entities/door_device.dart';
import '../../domain/repositories/door_detail_repository.dart';
import '../data_sources/door_detail_remote_data_source.dart';
import '../dto/door_detail_response_dto.dart';
import '../dto/door_device_response_dto.dart';

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

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
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
      final devices = await remoteDataSource.fetchDoorDevices(
        doorId: parsedDoorId,
        requestId: requestId,
      );
      return devices.map((device) => device.toDomain()).toList();
    } on DoorDetailRemoteException catch (error, stackTrace) {
      final appError = _mapError(error, requestId, doorId);
      logger.error(
        'Failed to fetch door devices',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'errorKind': error.kind.name},
      );
      throw appError;
    }
  }

  @override
  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) async {
    final parsedDoorId = int.tryParse(doorId.trim());
    final parsedDeviceId = int.tryParse(deviceId.trim());
    if (parsedDoorId == null || parsedDeviceId == null) {
      throw AppError(
        code: AppErrorCode.unknown,
        messageKey: 'door_device_invalid_id',
        requestId: requestId,
        deviceId: deviceId,
      );
    }

    try {
      await remoteDataSource.unbindDoorDevice(
        doorId: parsedDoorId,
        deviceId: parsedDeviceId,
        requestId: requestId,
      );
      logger.info(
        'Unbound door device',
        requestId: requestId,
        context: {'doorId': doorId, 'deviceId': deviceId},
      );
    } on DoorDetailRemoteException catch (error, stackTrace) {
      final appError = _mapError(error, requestId, deviceId);
      logger.error(
        'Failed to unbind door device',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'doorId': doorId,
          'deviceId': deviceId,
          'errorKind': error.kind.name,
        },
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

extension DoorDeviceResponseDtoMapper on DoorDeviceResponseDto {
  DoorDevice toDomain() => DoorDevice(
    deviceId: deviceId,
    sn: sn.trim(),
    deviceType: deviceType.trim(),
    deviceTypeLabel: deviceTypeLabel?.trim(),
    onlineStatus: onlineStatus,
    onlineStatusLabel: onlineStatusLabel?.trim(),
    bleName: bleName?.trim(),
    bleUuid: bleUuid?.trim(),
    bleMac: bleMac?.trim(),
    bleConnectionStatus: bleConnectionStatus,
    bleConnectionStatusLabel: bleConnectionStatusLabel?.trim(),
    wifiConnectionStatus: wifiConnectionStatus,
    wifiConnectionStatusLabel: wifiConnectionStatusLabel?.trim(),
    capabilities: capabilities,
  );
}

extension DoorDetailResponseDtoMapper on DoorDetailResponseDto {
  DoorDetail toDomain() {
    return DoorDetail(
      id: id,
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
      ledStatus: ledStatus,
      ledStatusLabel: ledStatusLabel,
      autoCloseEnabled: autoCloseEnabled ?? false,
      openReminderEnabled: openReminderEnabled ?? false,
      partialOpenValue: partialOpenValue,
    );
  }

  DoorState _doorState() {
    switch (doorState) {
      case 1:
        return DoorState.closed;
      case 2:
        return DoorState.opening;
      case 3:
        return DoorState.open;
      case 4:
        return DoorState.closing;
      case 5:
        return DoorState.stopped;
    }
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
    return DoorState.unknown;
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
