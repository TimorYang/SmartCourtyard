import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/receiving_door.dart';
import '../../domain/repositories/receiving_devices_repository.dart';
import '../data_sources/receiving_devices_remote_data_source.dart';
import '../dto/receiving_door_response_dto.dart';

class ReceivingDevicesRepositoryImpl implements ReceivingDevicesRepository {
  const ReceivingDevicesRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final ReceivingDevicesRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<List<ReceivingDoor>> fetchReceivingDoors({
    required String requestId,
  }) async {
    try {
      final doors = await remoteDataSource.fetchReceivingDoors(
        requestId: requestId,
      );
      logger.info(
        'Fetched receiving doors.',
        requestId: requestId,
        context: {'doorCount': doors.length},
      );
      return doors.map((door) => door.toDomain()).toList(growable: false);
    } on ReceivingDevicesRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to fetch receiving doors.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  AppError _mapError(ReceivingDevicesRemoteException error, String requestId) {
    if (error.kind == ReceivingDevicesRemoteErrorKind.network &&
        (error.statusCode == 401 || error.statusCode == 403)) {
      return AppError(
        code: AppErrorCode.accessDenied,
        messageKey: 'receivingDevices.accessDenied',
        requestId: requestId,
      );
    }
    if (error.kind == ReceivingDevicesRemoteErrorKind.network) {
      return AppError(
        code: AppErrorCode.networkUnavailable,
        messageKey: 'receivingDevices.networkUnavailable',
        action: AppErrorAction.retry,
        requestId: requestId,
        retryable: true,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'receivingDevices.failed',
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }
}

extension ReceivingDoorResponseDtoMapper on ReceivingDoorResponseDto {
  ReceivingDoor toDomain() => ReceivingDoor(
    shareId: shareId,
    doorId: doorId,
    name: name.trim(),
    ownerEmail: ownerEmail.trim(),
    expiresAt: expiresAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(expiresAt!, isUtc: true),
  );
}
