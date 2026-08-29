import 'app_error.dart';
import '../network/network_exception.dart';

AppError mapNetworkExceptionToAppError(
  NetworkException exception, {
  required String requestId,
  String? deviceId,
}) {
  return switch (exception.category) {
    NetworkFailureCategory.networkUnavailable => AppError(
      code: AppErrorCode.networkUnavailable,
      messageKey: 'networkErrorUnavailable',
      action: AppErrorAction.retry,
      requestId: requestId,
      deviceId: deviceId,
      retryable: true,
    ),
    NetworkFailureCategory.sessionExpired => AppError(
      code: AppErrorCode.accessDenied,
      messageKey: 'networkErrorSessionExpired',
      requestId: requestId,
      deviceId: deviceId,
    ),
    NetworkFailureCategory.accessDenied => AppError(
      code: AppErrorCode.accessDenied,
      messageKey: 'networkErrorAccessDenied',
      requestId: requestId,
      deviceId: deviceId,
    ),
    NetworkFailureCategory.requestTimeout => AppError(
      code: AppErrorCode.serverError,
      messageKey: 'networkErrorRequestTimeout',
      action: AppErrorAction.retry,
      requestId: requestId,
      deviceId: deviceId,
      retryable: true,
    ),
    NetworkFailureCategory.rateLimited => AppError(
      code: AppErrorCode.serverError,
      messageKey: 'networkErrorRateLimited',
      action: AppErrorAction.retry,
      requestId: requestId,
      deviceId: deviceId,
      retryable: true,
    ),
    NetworkFailureCategory.serviceUnavailable => AppError(
      code: AppErrorCode.serverError,
      messageKey: 'networkErrorServiceUnavailable',
      action: AppErrorAction.retry,
      requestId: requestId,
      deviceId: deviceId,
      retryable: true,
    ),
    NetworkFailureCategory.requestFailed ||
    NetworkFailureCategory.cancelled ||
    NetworkFailureCategory.unknown => AppError(
      code: AppErrorCode.serverError,
      messageKey: 'networkErrorRequestFailed',
      requestId: requestId,
      deviceId: deviceId,
    ),
  };
}
