import 'package:dio/dio.dart';
import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/network_exception.dart';
import 'package:flinx/features/auth/data/data_sources/auth_login_remote_data_source.dart';
import 'package:flinx/features/auth/data/dto/apple_login_nonce_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_login_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_profile_response_dto.dart';
import 'package:flinx/features/auth/data/dto/facebook_login_nonce_response_dto.dart';
import 'package:flinx/features/auth/data/dto/google_login_nonce_response_dto.dart';
import 'package:flinx/features/auth/domain/entities/facebook_identity_credential.dart';
import 'package:flinx/features/auth/data/repositories/auth_login_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds the Apple request and omits unavailable names', () async {
    final remoteDataSource = _FakeAuthLoginRemoteDataSource();
    final repository = AuthLoginRepositoryImpl(
      remoteDataSource: remoteDataSource,
      logger: const _SilentAppLogger(),
    );

    await repository.loginWithApple(
      nonceId: 'nonce-id',
      identityToken: 'identity-token',
      authorizationCode: 'authorization-code',
      givenName: '  ',
      familyName: null,
      deviceId: 'installation-id',
      deviceModel: 'iPhone17,2',
      platform: 'IOS',
      appVersion: '1.0.0',
      requestId: 'apple-login-123',
    );

    expect(remoteDataSource.request, {
      'nonceId': 'nonce-id',
      'identityToken': 'identity-token',
      'authorizationCode': 'authorization-code',
      'deviceId': 'installation-id',
      'deviceModel': 'iPhone17,2',
      'platform': 'IOS',
      'appVersion': '1.0.0',
    });
    expect(remoteDataSource.requestId, 'apple-login-123');
  });

  test('builds the Google request with the identity credentials', () async {
    final remoteDataSource = _FakeAuthLoginRemoteDataSource();
    final repository = AuthLoginRepositoryImpl(
      remoteDataSource: remoteDataSource,
      logger: const _SilentAppLogger(),
    );

    await repository.loginWithGoogle(
      nonceId: 'google-nonce-id',
      idToken: 'google-id-token',
      authorizationCode: 'google-authorization-code',
      deviceId: 'installation-id',
      deviceModel: 'iPhone17,2',
      platform: 'IOS',
      appVersion: '1.0.0',
      requestId: 'google-login-123',
    );

    expect(remoteDataSource.request, {
      'nonceId': 'google-nonce-id',
      'idToken': 'google-id-token',
      'authorizationCode': 'google-authorization-code',
      'deviceId': 'installation-id',
      'deviceModel': 'iPhone17,2',
      'platform': 'IOS',
      'appVersion': '1.0.0',
    });
    expect(remoteDataSource.requestId, 'google-login-123');
  });

  test(
    'builds the iOS Facebook request with the authentication token',
    () async {
      final remoteDataSource = _FakeAuthLoginRemoteDataSource();
      final repository = AuthLoginRepositoryImpl(
        remoteDataSource: remoteDataSource,
        logger: const _SilentAppLogger(),
      );

      await repository.loginWithFacebook(
        credential: const FacebookIdentityCredential(
          kind: FacebookTokenKind.authenticationToken,
          tokenString: 'jwt-token',
        ),
        nonceId: 'facebook-nonce-id',
        deviceId: 'installation-id',
        deviceModel: 'iPhone17,2',
        platform: 'IOS',
        appVersion: '1.0.0',
        requestId: 'facebook-login-ios-123',
      );

      expect(remoteDataSource.request, {
        'nonceId': 'facebook-nonce-id',
        'authenticationToken': 'jwt-token',
        'deviceId': 'installation-id',
        'deviceModel': 'iPhone17,2',
        'platform': 'IOS',
        'appVersion': '1.0.0',
      });
      expect(remoteDataSource.requestId, 'facebook-login-ios-123');
    },
  );

  test('builds the Android Facebook request without a nonce field', () async {
    final remoteDataSource = _FakeAuthLoginRemoteDataSource();
    final repository = AuthLoginRepositoryImpl(
      remoteDataSource: remoteDataSource,
      logger: const _SilentAppLogger(),
    );

    await repository.loginWithFacebook(
      credential: const FacebookIdentityCredential(
        kind: FacebookTokenKind.accessToken,
        tokenString: 'access-token',
      ),
      nonceId: 'must-not-be-sent',
      deviceId: 'installation-id',
      deviceModel: 'Pixel 9',
      platform: 'ANDROID',
      appVersion: '1.0.0',
      requestId: 'facebook-login-android-123',
    );

    expect(remoteDataSource.request, {
      'accessToken': 'access-token',
      'deviceId': 'installation-id',
      'deviceModel': 'Pixel 9',
      'platform': 'ANDROID',
      'appVersion': '1.0.0',
    });
    expect(remoteDataSource.requestId, 'facebook-login-android-123');
  });

  test('maps a login business message to AppError.userMessage', () async {
    final requestOptions = RequestOptions(path: 'app/auth/login');
    final repository = AuthLoginRepositoryImpl(
      remoteDataSource: _FakeAuthLoginRemoteDataSource(
        loginError: AuthLoginRemoteException.fromNetwork(
          NetworkException.fromDio(
            DioException.badResponse(
              statusCode: 400,
              requestOptions: requestOptions,
              response: Response<dynamic>(
                requestOptions: requestOptions,
                statusCode: 400,
                data: const {
                  'code': 100001,
                  'msg': 'Account or password error.',
                  'messageKey': 'account_or_password_error',
                },
              ),
            ),
          ),
        ),
      ),
      logger: const _SilentAppLogger(),
    );

    await expectLater(
      repository.login(
        email: 'alice@example.com',
        passwordCiphertext: 'ciphertext',
        keyId: 'key-1',
        nonce: 'nonce-1',
        deviceId: 'installation-id',
        deviceModel: 'iPhone17,2',
        platform: 'IOS',
        appVersion: '1.0.0',
        requestId: 'login-123',
      ),
      throwsA(
        isA<AppError>()
            .having((error) => error.businessCode, 'business code', 100001)
            .having(
              (error) => error.businessMessageKey,
              'message key',
              'account_or_password_error',
            )
            .having(
              (error) => error.userMessage,
              'user message',
              'Account or password error.',
            ),
      ),
    );
  });
}

class _FakeAuthLoginRemoteDataSource implements AuthLoginRemoteDataSource {
  _FakeAuthLoginRemoteDataSource({this.loginError});

  final AuthLoginRemoteException? loginError;
  Map<String, dynamic>? request;
  String? requestId;

  @override
  Future<AuthLoginRemoteResult> loginWithApple({
    required Map<String, dynamic> request,
    required String requestId,
  }) async {
    this.request = request;
    this.requestId = requestId;
    return const AuthLoginRemoteResult(
      login: AuthLoginResponseDto(
        accountId: '2',
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        tokenType: 'bearer',
        expiresInSeconds: 7200,
        refreshExpiresInSeconds: 2592000,
      ),
      profile: AuthProfileResponseDto(
        userId: '2',
        email: 'alice@example.com',
        emailVerified: true,
        nickname: 'Alice',
        regionCode: 'NL',
        locale: 'en-NL',
        timezone: 'Europe/Amsterdam',
      ),
    );
  }

  @override
  Future<AppleLoginNonceResponseDto> fetchAppleLoginNonce({
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<AuthLoginRemoteResult> loginWithGoogle({
    required Map<String, dynamic> request,
    required String requestId,
  }) async {
    this.request = request;
    this.requestId = requestId;
    return const AuthLoginRemoteResult(
      login: AuthLoginResponseDto(
        accountId: '2',
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        tokenType: 'bearer',
        expiresInSeconds: 7200,
        refreshExpiresInSeconds: 2592000,
      ),
      profile: AuthProfileResponseDto(
        userId: '2',
        email: 'alice@example.com',
        emailVerified: true,
        nickname: 'Alice',
        regionCode: 'NL',
        locale: 'en-NL',
        timezone: 'Europe/Amsterdam',
      ),
    );
  }

  @override
  Future<AuthLoginRemoteResult> loginWithFacebook({
    required Map<String, dynamic> request,
    required String requestId,
  }) async {
    this.request = request;
    this.requestId = requestId;
    return const AuthLoginRemoteResult(
      login: AuthLoginResponseDto(
        accountId: '2',
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        tokenType: 'bearer',
        expiresInSeconds: 7200,
        refreshExpiresInSeconds: 2592000,
      ),
      profile: AuthProfileResponseDto(
        userId: '2',
        email: 'alice@example.com',
        emailVerified: true,
        nickname: 'Alice',
        regionCode: 'NL',
        locale: 'en-NL',
        timezone: 'Europe/Amsterdam',
      ),
    );
  }

  @override
  Future<GoogleLoginNonceResponseDto> fetchGoogleLoginNonce({
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<FacebookLoginNonceResponseDto> fetchFacebookLoginNonce({
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<AuthLoginRemoteResult> login({
    required Map<String, dynamic> request,
    required String requestId,
  }) async {
    this.request = request;
    this.requestId = requestId;
    final error = loginError;
    if (error != null) throw error;
    return const AuthLoginRemoteResult(
      login: AuthLoginResponseDto(
        accountId: '2',
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        tokenType: 'bearer',
        expiresInSeconds: 7200,
        refreshExpiresInSeconds: 2592000,
      ),
      profile: AuthProfileResponseDto(
        userId: '2',
        email: 'alice@example.com',
        emailVerified: true,
        nickname: 'Alice',
        regionCode: 'NL',
        locale: 'en-NL',
        timezone: 'Europe/Amsterdam',
      ),
    );
  }
}

class _SilentAppLogger implements AppLogger {
  const _SilentAppLogger();

  @override
  void error(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void info(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void warning(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}
}
