import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/auto_close_check_result.dart';
import '../../domain/repositories/auto_close_check_repository.dart';
import '../data_sources/auto_close_check_remote_data_source.dart';

class AutoCloseCheckRepositoryImpl implements AutoCloseCheckRepository {
  const AutoCloseCheckRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final AutoCloseCheckRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<AutoCloseCheckResult> checkAutoClose({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) async {
    final parsedDoorId = int.tryParse(doorId.trim());
    final parsedDeviceId = int.tryParse(deviceId.trim());
    if (parsedDoorId == null || parsedDeviceId == null) {
      throw AppError(
        code: AppErrorCode.unknown,
        messageKey: 'auto_close_check_invalid_id',
        requestId: requestId,
        deviceId: deviceId,
      );
    }

    try {
      final response = await remoteDataSource.checkAutoClose(
        doorId: parsedDoorId,
        deviceId: parsedDeviceId,
        requestId: requestId,
      );
      final allowed = response.autoCloseAllowed;
      if (allowed == null) {
        throw const AutoCloseCheckRemoteException.invalidResponse();
      }
      return AutoCloseCheckResult(autoCloseAllowed: allowed);
    } on AutoCloseCheckRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to check auto-close availability',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'doorId': doorId,
          'deviceId': deviceId,
          'errorKind': error.kind.name,
        },
      );
      if (error.kind == AutoCloseCheckRemoteErrorKind.network &&
          error.network != null) {
        throw mapNetworkExceptionToAppError(
          error.network!,
          requestId: requestId,
          deviceId: deviceId,
        );
      }
      throw AppError(
        code: AppErrorCode.serverError,
        messageKey: 'auto_close_check_invalid_response',
        businessCode: error.businessFailure?.code,
        businessMessageKey: error.businessFailure?.messageKey,
        userMessage: error.kind == AutoCloseCheckRemoteErrorKind.businessFailure
            ? error.businessFailure?.message
            : null,
        action: AppErrorAction.retry,
        requestId: requestId,
        deviceId: deviceId,
        retryable: true,
      );
    }
  }
}
