import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/password_encryption_material.dart';
import '../../domain/repositories/auth_crypto_repository.dart';
import '../data_sources/auth_crypto_remote_data_source.dart';

class AuthCryptoRepositoryImpl implements AuthCryptoRepository {
  AuthCryptoRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AuthCryptoRemoteDataSource remoteDataSource;
  final AppLogger logger;
  final DateTime Function() _clock;

  @override
  Future<PasswordEncryptionMaterial> getPasswordEncryptionMaterial({
    required String requestId,
  }) async {
    try {
      final dto = await remoteDataSource.fetchPublicKeyAndNonce(
        requestId: requestId,
      );
      final material = PasswordEncryptionMaterial(
        keyId: dto.keyId,
        algorithm: dto.algorithm,
        publicKeyBase64: dto.publicKey,
        nonce: dto.nonce,
        expiresIn: Duration(seconds: dto.expiresInSeconds),
        requestId: requestId,
        issuedAt: _clock().toUtc(),
      );
      logger.info(
        'Fetched password encryption material.',
        requestId: requestId,
        context: {'expiresInSeconds': dto.expiresInSeconds},
      );
      return material;
    } on AuthCryptoRemoteException catch (error, stackTrace) {
      final appError = _mapError(error, requestId);
      logger.error(
        'Failed to fetch password encryption material.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'statusCode': error.statusCode,
          'businessCode': error.businessFailure?.code,
          'businessMessageKey': error.businessFailure?.messageKey,
        },
      );
      throw appError;
    }
  }

  AppError _mapError(AuthCryptoRemoteException error, String requestId) {
    if (error.kind == AuthCryptoRemoteErrorKind.network &&
        error.network != null &&
        error.statusCode != 401 &&
        error.statusCode != 403) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
      );
    }
    return switch (error.kind) {
      AuthCryptoRemoteErrorKind.configuration => AppError(
        code: AppErrorCode.unknown,
        messageKey: 'auth.crypto.configurationUnavailable',
        requestId: requestId,
      ),
      AuthCryptoRemoteErrorKind.network
          when error.statusCode == 401 || error.statusCode == 403 =>
        AppError(
          code: AppErrorCode.accessDenied,
          messageKey: 'auth.crypto.clientAuthorizationFailed',
          requestId: requestId,
        ),
      AuthCryptoRemoteErrorKind.network when error.network == null => AppError(
        code: AppErrorCode.networkUnavailable,
        messageKey: 'auth.crypto.networkUnavailable',
        action: AppErrorAction.retry,
        requestId: requestId,
        retryable: true,
      ),
      AuthCryptoRemoteErrorKind.businessFailure => AppError(
        code: AppErrorCode.serverError,
        messageKey: 'auth.crypto.unavailable',
        businessCode: error.businessFailure?.code,
        businessMessageKey: error.businessFailure?.messageKey,
        userMessage: error.businessFailure?.message,
        action: AppErrorAction.retry,
        requestId: requestId,
        retryable: true,
      ),
      AuthCryptoRemoteErrorKind.network ||
      AuthCryptoRemoteErrorKind.invalidResponse => AppError(
        code: AppErrorCode.serverError,
        messageKey: 'auth.crypto.unavailable',
        action: AppErrorAction.retry,
        requestId: requestId,
        retryable: true,
      ),
    };
  }
}
