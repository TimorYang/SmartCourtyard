import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/features/auth/data/data_sources/auth_login_remote_data_source.dart';
import 'package:flinx/features/auth/data/dto/apple_login_nonce_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_login_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_profile_response_dto.dart';
import 'package:flinx/features/auth/data/dto/google_login_nonce_response_dto.dart';
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
}

class _FakeAuthLoginRemoteDataSource implements AuthLoginRemoteDataSource {
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
  Future<GoogleLoginNonceResponseDto> fetchGoogleLoginNonce({
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<AuthLoginRemoteResult> login({
    required Map<String, dynamic> request,
    required String requestId,
  }) => throw UnimplementedError();
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
