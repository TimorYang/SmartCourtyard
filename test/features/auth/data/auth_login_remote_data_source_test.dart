import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/auth/data/data_sources/auth_api.dart';
import 'package:flinx/features/auth/data/data_sources/auth_login_remote_data_source.dart';
import 'package:flinx/features/auth/data/dto/auth_public_key_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_login_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_profile_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'submits the encrypted login request and accepts response code 200',
    () async {
      final api = _FakeAuthApi(
        const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: AuthLoginResponseDto(
            accountId: '2',
            accessToken: 'access-token',
            refreshToken: 'refresh-token',
            tokenType: 'bearer',
            expiresInSeconds: 86400,
            refreshExpiresInSeconds: 2592000,
          ),
        ),
      );
      final dataSource = AuthLoginRemoteDataSourceImpl(
        api: api,
        clientAuthorization: 'encoded-client-credentials',
      );

      final result = await dataSource.login(
        requestId: 'login-123',
        request: const {
          'email': 'alice@example.com',
          'keyId': 'app-password-key-v1',
          'nonce': 'one-time-nonce',
          'passwordCiphertext': 'ciphertext',
          'deviceId': 'installation-id',
          'deviceModel': 'iPhone17,2',
          'platform': 'IOS',
          'appVersion': '1.0.0',
        },
      );

      expect(api.body, containsPair('email', 'alice@example.com'));
      expect(api.body, containsPair('passwordCiphertext', 'ciphertext'));
      expect(api.body, containsPair('deviceId', 'installation-id'));
      expect(api.body, containsPair('deviceModel', 'iPhone17,2'));
      expect(api.body, containsPair('platform', 'IOS'));
      expect(api.body, containsPair('appVersion', '1.0.0'));
      expect(
        api.loginOptions.headers?['authorization'],
        'Basic encoded-client-credentials',
      );
      expect(api.profileOptions.headers?['Blade-Auth'], 'access-token');
      expect(
        api.profileOptions.extra?[NetworkRequestExtras.requestId],
        'login-123',
      );
      expect(
        api.profileOptions.extra?[NetworkRequestExtras.skipTokenRefresh],
        isTrue,
      );
      expect(result.profile.userId, '2');
      expect(result.profile.email, 'alice@example.com');
      expect(result.profile.regionCode, 'NL');
    },
  );

  test('rejects a non-200 business response code', () async {
    final dataSource = AuthLoginRemoteDataSourceImpl(
      api: _FakeAuthApi(
        const ApiEnvelopeDto<AuthLoginResponseDto>(code: 400, success: true),
      ),
      clientAuthorization: 'encoded-client-credentials',
    );

    expect(
      () => dataSource.login(requestId: 'login-123', request: const {}),
      throwsA(
        isA<AuthLoginRemoteException>().having(
          (error) => error.kind,
          'kind',
          AuthLoginRemoteErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('rejects a login response whose success flag is false', () async {
    final dataSource = AuthLoginRemoteDataSourceImpl(
      api: _FakeAuthApi(
        const ApiEnvelopeDto<AuthLoginResponseDto>(
          code: 200,
          success: false,
          data: AuthLoginResponseDto(
            accountId: '2',
            accessToken: 'access-token',
            refreshToken: 'refresh-token',
            tokenType: 'bearer',
            expiresInSeconds: 86400,
            refreshExpiresInSeconds: 2592000,
          ),
        ),
      ),
      clientAuthorization: 'encoded-client-credentials',
    );

    expect(
      () => dataSource.login(requestId: 'login-123', request: const {}),
      throwsA(
        isA<AuthLoginRemoteException>().having(
          (error) => error.kind,
          'kind',
          AuthLoginRemoteErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('rejects a profile response whose success flag is false', () async {
    final dataSource = AuthLoginRemoteDataSourceImpl(
      api: _FakeAuthApi(
        const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: AuthLoginResponseDto(
            accountId: '2',
            accessToken: 'access-token',
            refreshToken: 'refresh-token',
            tokenType: 'bearer',
            expiresInSeconds: 86400,
            refreshExpiresInSeconds: 2592000,
          ),
        ),
        profileResponse: const ApiEnvelopeDto(
          code: 200,
          success: false,
          data: AuthProfileResponseDto(
            userId: '2',
            email: 'alice@example.com',
            emailVerified: true,
            nickname: 'Alice',
            regionCode: 'NL',
            locale: 'zh-Hans-NL',
            timezone: 'Asia/Shanghai',
          ),
        ),
      ),
      clientAuthorization: 'encoded-client-credentials',
    );

    expect(
      () => dataSource.login(requestId: 'login-123', request: const {}),
      throwsA(isA<AuthLoginRemoteException>()),
    );
  });
}

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi(
    this.response, {
    this.profileResponse = const ApiEnvelopeDto(
      code: 200,
      success: true,
      data: AuthProfileResponseDto(
        userId: '2',
        email: 'alice@example.com',
        emailVerified: true,
        nickname: 'Alice',
        regionCode: 'NL',
        locale: 'zh-Hans-NL',
        timezone: 'Asia/Shanghai',
      ),
    ),
  });

  final ApiEnvelopeDto<AuthLoginResponseDto> response;
  final ApiEnvelopeDto<AuthProfileResponseDto> profileResponse;
  late Map<String, dynamic> body;
  late Options loginOptions;
  late Options profileOptions;

  @override
  Future<ApiEnvelopeDto<AuthLoginResponseDto>> login(
    Map<String, dynamic> requestBody,
    Options requestOptions,
  ) async {
    body = requestBody;
    loginOptions = requestOptions;
    return response;
  }

  @override
  Future<ApiEnvelopeDto<AuthLoginResponseDto>> refreshToken(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<AuthProfileResponseDto>> fetchAccountProfile(
    Options requestOptions,
  ) async {
    profileOptions = requestOptions;
    return profileResponse;
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> completeRegistration(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> completePasswordReset(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<AuthPublicKeyResponseDto>> fetchPublicKey(
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> sendRegistrationEmailCode(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> sendPasswordResetEmailCode(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> verifyRegistrationEmailCode(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> verifyPasswordResetEmailCode(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();
}
