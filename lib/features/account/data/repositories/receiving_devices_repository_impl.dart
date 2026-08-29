import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
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
        error.network != null) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'receivingDevices.failed',
      businessCode: error.businessFailure?.code,
      businessMessageKey: error.businessFailure?.messageKey,
      userMessage: error.kind == ReceivingDevicesRemoteErrorKind.businessFailure
          ? error.businessFailure?.message
          : null,
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
    coverFileId: coverFileId,
    doorType: doorType,
    expiresAt: expiresAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(expiresAt!, isUtc: true),
  );
}
