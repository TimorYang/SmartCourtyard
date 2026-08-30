import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../account/domain/entities/account_profile.dart';
import '../../../account/domain/entities/account_avatar_code.dart';
import '../../../account/domain/entities/account_token_set.dart';
import '../../domain/entities/apple_login_nonce.dart';
import '../../domain/entities/auth_login_result.dart';
import '../../domain/entities/google_login_nonce.dart';
import '../../domain/repositories/auth_login_repository.dart';
import '../data_sources/auth_login_remote_data_source.dart';

class AuthLoginRepositoryImpl implements AuthLoginRepository {
  AuthLoginRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final AuthLoginRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<AuthLoginResult> login({
    required String email,
    required String passwordCiphertext,
    required String keyId,
    required String nonce,
    required String deviceId,
    required String deviceModel,
    required String platform,
    required String appVersion,
    required String requestId,
  }) async {
    try {
      final result = await remoteDataSource.login(
        requestId: requestId,
        request: {
          'email': email,
          'keyId': keyId,
          'nonce': nonce,
          'passwordCiphertext': passwordCiphertext,
          'deviceId': deviceId,
          'deviceModel': deviceModel,
          'platform': platform,
          'appVersion': appVersion,
        },
      );
      logger.info('Completed login.', requestId: requestId);
      return _mapResult(result);
    } on AuthLoginRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to login.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<AuthLoginResult> loginWithApple({
    required String nonceId,
    required String identityToken,
    required String authorizationCode,
    required String? givenName,
    required String? familyName,
    required String deviceId,
    required String deviceModel,
    required String platform,
    required String appVersion,
    required String requestId,
  }) async {
    try {
      final result = await remoteDataSource.loginWithApple(
        request: {
          'nonceId': nonceId,
          'identityToken': identityToken,
          'authorizationCode': authorizationCode,
          if (givenName?.trim().isNotEmpty ?? false)
            'givenName': givenName!.trim(),
          if (familyName?.trim().isNotEmpty ?? false)
            'familyName': familyName!.trim(),
          'deviceId': deviceId,
          'deviceModel': deviceModel,
          'platform': platform,
          'appVersion': appVersion,
        },
        requestId: requestId,
      );
      logger.info('Completed Apple login.', requestId: requestId);
      return _mapResult(result);
    } on AuthLoginRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed Apple login.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<AuthLoginResult> loginWithGoogle({
    required String nonceId,
    required String idToken,
    required String authorizationCode,
    required String deviceId,
    required String deviceModel,
    required String platform,
    required String appVersion,
    required String requestId,
  }) async {
    try {
      final result = await remoteDataSource.loginWithGoogle(
        request: {
          'nonceId': nonceId,
          'idToken': idToken,
          'authorizationCode': authorizationCode,
          'deviceId': deviceId,
          'deviceModel': deviceModel,
          'platform': platform,
          'appVersion': appVersion,
        },
        requestId: requestId,
      );
      logger.info('Completed Google login.', requestId: requestId);
      return _mapResult(result);
    } on AuthLoginRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed Google login.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<AppleLoginNonce> getAppleLoginNonce({
    required String requestId,
  }) async {
    try {
      final dto = await remoteDataSource.fetchAppleLoginNonce(
        requestId: requestId,
      );
      logger.info(
        'Fetched Apple login nonce.',
        requestId: requestId,
        context: {'expiresInSeconds': dto.expiresInSeconds},
      );
      return AppleLoginNonce(
        nonceId: dto.nonceId,
        nonce: dto.nonce,
        expiresIn: Duration(seconds: dto.expiresInSeconds),
      );
    } on AuthLoginRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to fetch Apple login nonce.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<GoogleLoginNonce> getGoogleLoginNonce({
    required String requestId,
  }) async {
    try {
      final dto = await remoteDataSource.fetchGoogleLoginNonce(
        requestId: requestId,
      );
      logger.info(
        'Fetched Google login nonce.',
        requestId: requestId,
        context: {'expiresInSeconds': dto.expiresInSeconds},
      );
      return GoogleLoginNonce(
        nonceId: dto.nonceId,
        nonce: dto.nonce,
        expiresIn: Duration(seconds: dto.expiresInSeconds),
      );
    } on AuthLoginRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to fetch Google login nonce.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  AuthLoginResult _mapResult(AuthLoginRemoteResult result) {
    return AuthLoginResult(
      tokenSet: AccountTokenSet(
        accessToken: result.login.accessToken,
        refreshToken: result.login.refreshToken,
        tokenType: result.login.tokenType,
        expiresAt: DateTime.now().toUtc().add(
          Duration(seconds: result.login.expiresInSeconds),
        ),
        refreshExpiresAt: DateTime.now().toUtc().add(
          Duration(seconds: result.login.refreshExpiresInSeconds),
        ),
      ),
      profile: AccountProfile(
        userId: result.profile.userId,
        email: result.profile.email,
        nickname: result.profile.nickname,
        country: result.profile.regionCode,
        avatarFileId: result.profile.avatarFileId,
        avatarCode: AccountAvatarCode.fromWireValue(result.profile.avatarCode),
      ),
    );
  }

  AppError _mapError(AuthLoginRemoteException error, String requestId) {
    if (error.kind == AuthLoginRemoteErrorKind.configuration) {
      return AppError(
        code: AppErrorCode.unknown,
        messageKey: 'auth.login.configurationUnavailable',
        requestId: requestId,
      );
    }
    if (error.kind == AuthLoginRemoteErrorKind.network &&
        (error.statusCode == 401 || error.statusCode == 403)) {
      return AppError(
        code: AppErrorCode.accessDenied,
        messageKey: 'auth.login.accessDenied',
        requestId: requestId,
      );
    }
    if (error.kind == AuthLoginRemoteErrorKind.network &&
        error.network != null) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'auth.login.failed',
      businessCode: error.businessFailure?.code,
      businessMessageKey: error.businessFailure?.messageKey,
      userMessage: error.kind == AuthLoginRemoteErrorKind.businessFailure
          ? error.businessFailure?.message
          : null,
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }
}
