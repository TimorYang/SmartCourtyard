import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/push_registration.dart';
import '../../domain/repositories/push_registration_repository.dart';
import '../data_sources/engage_lab_push_remote_data_source.dart';

class PushRegistrationRepositoryImpl implements PushRegistrationRepository {
  const PushRegistrationRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final EngageLabPushRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<void> bind({
    required PushRegistration registration,
    required String requestId,
  }) async {
    try {
      await remoteDataSource.bind(
        registration: registration,
        requestId: requestId,
      );
    } on EngageLabPushRemoteException catch (error, stackTrace) {
      throw _mapError(error, requestId, stackTrace);
    }
  }

  @override
  Future<void> unbind({required String requestId}) async {
    try {
      await remoteDataSource.unbind(requestId: requestId);
    } on EngageLabPushRemoteException catch (error, stackTrace) {
      throw _mapError(error, requestId, stackTrace);
    }
  }

  AppError _mapError(
    EngageLabPushRemoteException error,
    String requestId,
    StackTrace stackTrace,
  ) {
    logger.error(
      'push_registration_request_failed',
      tag: AppLogTag.push,
      requestId: requestId,
      error: error,
      stackTrace: stackTrace,
      context: <String, Object?>{
        'kind': error.kind.name,
        'statusCode': error.statusCode,
      },
    );

    if (error.kind == EngageLabPushRemoteErrorKind.network &&
        error.network != null) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
      );
    }

    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'networkErrorRequestFailed',
      businessCode: error.businessFailure?.code,
      businessMessageKey: error.businessFailure?.messageKey,
      userMessage: error.businessFailure?.message,
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }
}
