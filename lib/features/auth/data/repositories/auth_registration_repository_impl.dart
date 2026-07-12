import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/registration_verification.dart';
import '../../domain/repositories/auth_registration_repository.dart';
import '../data_sources/auth_registration_remote_data_source.dart';

class AuthRegistrationRepositoryImpl implements AuthRegistrationRepository {
  AuthRegistrationRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final AuthRegistrationRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<void> sendEmailCode({
    required String email,
    required String requestId,
  }) => _run(
    requestId: requestId,
    operation: 'send registration email code',
    action: () =>
        remoteDataSource.sendEmailCode(email: email, requestId: requestId),
  );

  @override
  Future<RegistrationVerification> verifyEmailCode({
    required String email,
    required String code,
    required String requestId,
  }) => _run(
    requestId: requestId,
    operation: 'verify registration email code',
    action: () => remoteDataSource.verifyEmailCode(
      email: email,
      code: code,
      requestId: requestId,
    ),
  );

  @override
  Future<void> completeRegistration({
    required String registrationToken,
    required String passwordCiphertext,
    required String confirmPasswordCiphertext,
    required String keyId,
    required String nonce,
    required String locale,
    required String timezone,
    String? regionCode,
    required String requestId,
  }) => _run(
    requestId: requestId,
    operation: 'complete registration',
    action: () => remoteDataSource.completeRegistration(
      requestId: requestId,
      request: {
        'registrationToken': registrationToken,
        'passwordCiphertext': passwordCiphertext,
        'confirmPasswordCiphertext': confirmPasswordCiphertext,
        'keyId': keyId,
        'nonce': nonce,
        'locale': locale,
        'timezone': timezone,
        if (regionCode != null && regionCode.isNotEmpty)
          'regionCode': regionCode,
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
    } on AuthRegistrationRemoteException catch (error, stackTrace) {
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

  AppError _mapError(AuthRegistrationRemoteException error, String requestId) {
    if (error.kind == AuthRegistrationRemoteErrorKind.configuration) {
      return AppError(
        code: AppErrorCode.unknown,
        messageKey: 'auth.registration.configurationUnavailable',
        requestId: requestId,
      );
    }
    if (error.kind == AuthRegistrationRemoteErrorKind.network &&
        (error.statusCode == 401 || error.statusCode == 403)) {
      return AppError(
        code: AppErrorCode.accessDenied,
        messageKey: 'auth.registration.clientAuthorizationFailed',
        requestId: requestId,
      );
    }
    if (error.kind == AuthRegistrationRemoteErrorKind.network) {
      return AppError(
        code: AppErrorCode.networkUnavailable,
        messageKey: 'auth.registration.networkUnavailable',
        action: AppErrorAction.retry,
        requestId: requestId,
        retryable: true,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'auth.registration.unavailable',
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }
}
