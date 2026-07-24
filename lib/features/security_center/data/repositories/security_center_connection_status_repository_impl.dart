import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/security_center_connection_status.dart';
import '../../domain/repositories/security_center_connection_status_repository.dart';
import '../data_sources/security_center_connection_status_remote_data_source.dart';

class SecurityCenterConnectionStatusRepositoryImpl
    implements SecurityCenterConnectionStatusRepository {
  const SecurityCenterConnectionStatusRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final SecurityCenterConnectionStatusRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<SecurityCenterConnectionStatus> fetchConnectionStatus({
    required String doorId,
    required String requestId,
  }) async {
    final parsedDoorId = int.tryParse(doorId.trim());
    if (parsedDoorId == null) {
      throw AppError(
        code: AppErrorCode.unknown,
        messageKey: 'security_center_connection_status_invalid_door_id',
        requestId: requestId,
        deviceId: doorId,
      );
    }
    try {
      final dto = await remoteDataSource.fetchConnectionStatus(
        doorId: parsedDoorId,
        requestId: requestId,
      );
      return SecurityCenterConnectionStatus(
        wifiConnectionStatus: dto.wifiConnectionStatus!,
      );
    } on SecurityCenterConnectionStatusRemoteException catch (
      error,
      stackTrace
    ) {
      logger.error(
        'Failed to fetch security center connection status',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'errorKind': error.kind.name},
      );
      throw AppError(
        code:
            error.kind == SecurityCenterConnectionStatusRemoteErrorKind.network
            ? AppErrorCode.networkUnavailable
            : AppErrorCode.serverError,
        messageKey: 'security_center_connection_status_load_failed',
        action: AppErrorAction.retry,
        requestId: requestId,
        deviceId: doorId,
        retryable: true,
      );
    }
  }
}
