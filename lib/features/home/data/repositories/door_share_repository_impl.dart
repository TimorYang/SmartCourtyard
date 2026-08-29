import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/door_share.dart';
import '../../domain/repositories/door_share_repository.dart';
import '../data_sources/door_share_remote_data_source.dart';
import '../dto/door_share_dto.dart';

class DoorShareRepositoryImpl implements DoorShareRepository {
  const DoorShareRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });
  final DoorShareRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<List<ShareCapability>> fetchCapabilities({
    required int doorId,
    required String requestId,
  }) async {
    try {
      final response = await remoteDataSource.fetchCapabilities(
        doorId: doorId,
        requestId: requestId,
      );
      final capabilities = response
          .map((item) => ShareCapability.fromWireValue(item.code))
          .whereType<ShareCapability>()
          .toList(growable: false);
      logger.info(
        'Fetched door share capabilities.',
        requestId: requestId,
        context: {'doorId': doorId, 'capabilityCount': capabilities.length},
      );
      return capabilities;
    } on DoorShareRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to fetch door share capabilities.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<void> createShare({
    required int doorId,
    required CreateDoorShareCommand command,
    required String requestId,
  }) async {
    try {
      await remoteDataSource.createShare(
        doorId: doorId,
        requestId: requestId,
        request: CreateDoorShareRequestDto(
          receiverEmail: command.receiverEmail.trim(),
          role: command.role.wireValue,
          expiryType: command.expiryType.wireValue,
          expiresAt: command.expiresAtUtcMillis,
          capabilities: command.capabilities
              .map((item) => item.wireValue)
              .toList(growable: false),
          sendEmail: command.sendEmail,
        ),
      );
      logger.info(
        'Created door share.',
        requestId: requestId,
        context: {'doorId': doorId},
      );
    } on DoorShareRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to create door share.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<void> updateShare({
    required int shareId,
    required UpdateDoorShareCommand command,
    required String requestId,
  }) async {
    try {
      await remoteDataSource.updateShare(
        shareId: shareId,
        requestId: requestId,
        request: UpdateDoorShareRequestDto(
          role: command.role.wireValue,
          expiryType: command.expiryType.wireValue,
          expiresAt: command.expiresAtUtcMillis,
          capabilities: command.capabilities
              .map((item) => item.wireValue)
              .toList(growable: false),
        ),
      );
      logger.info(
        'Updated door share.',
        requestId: requestId,
        context: {'shareId': shareId},
      );
    } on DoorShareRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to update door share.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'shareId': shareId, 'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  AppError _mapError(DoorShareRemoteException error, String requestId) {
    if (error.kind == DoorShareRemoteErrorKind.network &&
        error.network != null) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'doorShare.failed',
      businessCode: error.businessFailure?.code,
      businessMessageKey: error.businessFailure?.messageKey,
      userMessage: error.kind == DoorShareRemoteErrorKind.businessFailure
          ? error.businessFailure?.message
          : null,
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }
}
