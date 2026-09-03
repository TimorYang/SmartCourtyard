import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/f_box_control_mode.dart';
import '../../domain/repositories/door_control_mode_repository.dart';
import '../data_sources/door_control_mode_remote_data_source.dart';

class DoorControlModeRepositoryImpl implements DoorControlModeRepository {
  const DoorControlModeRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final DoorControlModeRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<void> updateControlMode({
    required String sn,
    required FBoxControlMode mode,
    required String requestId,
  }) async {
    final normalizedSn = sn.trim();
    if (normalizedSn.isEmpty) {
      throw AppError(
        code: AppErrorCode.unknown,
        messageKey: 'door_control_mode_missing_sn',
        action: AppErrorAction.retry,
        requestId: requestId,
        retryable: true,
      );
    }

    try {
      await remoteDataSource.updateControlMode(
        sn: normalizedSn,
        controlMode: mode.apiValue,
        requestId: requestId,
      );
      logger.info(
        'Updated F-box control mode',
        requestId: requestId,
        context: {'controlMode': mode.apiValue},
      );
    } on DoorControlModeRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to update F-box control mode',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'controlMode': mode.apiValue,
          'errorKind': error.kind.name,
          'businessCode': error.businessFailure?.code,
          'businessMessageKey': error.businessFailure?.messageKey,
        },
      );
      throw _mapError(error, normalizedSn, requestId);
    }
  }

  AppError _mapError(
    DoorControlModeRemoteException error,
    String sn,
    String requestId,
  ) {
    if (error.kind == DoorControlModeRemoteErrorKind.network &&
        error.network != null) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
        deviceId: sn,
      );
    }

    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'door_control_mode_update_failed',
      businessCode: error.businessFailure?.code,
      businessMessageKey: error.businessFailure?.messageKey,
      userMessage: error.businessFailure?.message,
      action: AppErrorAction.retry,
      requestId: requestId,
      deviceId: sn,
      retryable: true,
    );
  }
}
