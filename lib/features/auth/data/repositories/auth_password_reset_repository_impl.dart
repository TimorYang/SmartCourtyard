import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/password_reset_verification.dart';
import '../../domain/repositories/auth_password_reset_repository.dart';
import '../data_sources/auth_password_reset_remote_data_source.dart';

class AuthPasswordResetRepositoryImpl implements AuthPasswordResetRepository {
  AuthPasswordResetRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final AuthPasswordResetRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<void> sendEmailCode({
    required String email,
    required String requestId,
  }) => _run(
    requestId: requestId,
    operation: 'send password reset email code',
    action: () =>
        remoteDataSource.sendEmailCode(email: email, requestId: requestId),
  );

  @override
  Future<PasswordResetVerification> verifyEmailCode({
    required String email,
    required String code,
    required String requestId,
  }) => _run<PasswordResetVerification>(
    requestId: requestId,
    operation: 'verify password reset email code',
    action: () => remoteDataSource.verifyEmailCode(
      email: email,
      code: code,
      requestId: requestId,
    ),
  );

  @override
  Future<void> completePasswordReset({
    required String passwordResetToken,
    required String newPasswordCiphertext,
    required String confirmPasswordCiphertext,
    required String keyId,
    required String nonce,
    required String requestId,
  }) => _run(
    requestId: requestId,
    operation: 'complete password reset',
    action: () => remoteDataSource.completePasswordReset(
      requestId: requestId,
      request: {
        'keyId': keyId,
        'nonce': nonce,
        'passwordResetToken': passwordResetToken,
        'newPasswordCiphertext': newPasswordCiphertext,
        'confirmPasswordCiphertext': confirmPasswordCiphertext,
      },
    ),
  );

  Future<T> _run<T>({
    required String requestId,
    required String operation,
    required Future<T> Function() action,
  }) async {
    try {
      final result = await action();
      logger.info('Completed $operation.', requestId: requestId);
      return result;
    } on AuthPasswordResetRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to $operation.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  AppError _mapError(AuthPasswordResetRemoteException error, String requestId) {
    if (error.kind == AuthPasswordResetRemoteErrorKind.network &&
        error.network != null &&
        error.statusCode != 401 &&
        error.statusCode != 403) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
      );
    }
    return switch (error.kind) {
      AuthPasswordResetRemoteErrorKind.configuration => AppError(
        code: AppErrorCode.unknown,
        messageKey: 'auth.passwordReset.configurationUnavailable',
        requestId: requestId,
      ),
      AuthPasswordResetRemoteErrorKind.network
          when error.statusCode == 401 || error.statusCode == 403 =>
        AppError(
          code: AppErrorCode.accessDenied,
          messageKey: 'auth.passwordReset.clientAuthorizationFailed',
          requestId: requestId,
        ),
      AuthPasswordResetRemoteErrorKind.businessFailure => AppError(
        code: AppErrorCode.serverError,
        messageKey: 'auth.passwordReset.unavailable',
        businessCode: error.businessFailure?.code,
        businessMessageKey: error.businessFailure?.messageKey,
        userMessage: error.businessFailure?.message,
        action: AppErrorAction.retry,
        requestId: requestId,
        retryable: true,
      ),
      AuthPasswordResetRemoteErrorKind.network ||
      AuthPasswordResetRemoteErrorKind.invalidResponse => AppError(
        code: AppErrorCode.serverError,
        messageKey: 'auth.passwordReset.unavailable',
        action: AppErrorAction.retry,
        requestId: requestId,
        retryable: true,
      ),
    };
  }
}
