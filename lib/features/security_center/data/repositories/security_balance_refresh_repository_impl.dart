import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/repositories/security_balance_refresh_repository.dart';
import '../../domain/entities/security_balance_refresh_result.dart';
import '../data_sources/security_balance_refresh_remote_data_source.dart';

class SecurityBalanceRefreshRepositoryImpl
    implements SecurityBalanceRefreshRepository {
  const SecurityBalanceRefreshRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final SecurityBalanceRefreshRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<SecurityBalanceRefreshResult> refreshBalance({
    required String doorId,
    required String requestId,
  }) async {
    final parsedDoorId = int.tryParse(doorId.trim());
    if (parsedDoorId == null) {
      throw AppError(
        code: AppErrorCode.unknown,
        messageKey: 'security_balance_refresh_invalid_door_id',
        requestId: requestId,
        deviceId: doorId,
      );
    }

    try {
      final dto = await remoteDataSource.refreshBalance(
        doorId: parsedDoorId,
        requestId: requestId,
      );
      final serverRequestId = dto.requestId?.trim();
      return SecurityBalanceRefreshResult(
        requestId: serverRequestId?.isEmpty ?? true ? null : serverRequestId,
        status: dto.status,
      );
    } on SecurityBalanceRefreshRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to trigger security balance refresh',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'errorKind': error.kind.name},
      );
      throw _mapError(error, requestId, doorId);
    }
  }

  AppError _mapError(
    SecurityBalanceRefreshRemoteException error,
    String requestId,
    String doorId,
  ) {
    if (error.kind == SecurityBalanceRefreshRemoteErrorKind.network &&
        error.network != null) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
        deviceId: doorId,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'security_balance_refresh_invalid_response',
      businessCode: error.businessFailure?.code,
      businessMessageKey: error.businessFailure?.messageKey,
      userMessage:
          error.kind == SecurityBalanceRefreshRemoteErrorKind.businessFailure
          ? error.businessFailure?.message
          : null,
      action: AppErrorAction.retry,
      requestId: requestId,
      deviceId: doorId,
      retryable: true,
    );
  }
}
