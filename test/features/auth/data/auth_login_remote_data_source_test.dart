import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/auth/data/data_sources/auth_api.dart';
import 'package:flinx/features/auth/data/data_sources/auth_login_remote_data_source.dart';
import 'package:flinx/features/auth/data/dto/apple_login_nonce_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_public_key_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_login_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_profile_response_dto.dart';
import 'package:flinx/features/auth/data/dto/facebook_login_nonce_response_dto.dart';
import 'package:flinx/features/auth/data/dto/google_login_nonce_response_dto.dart';
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

  test('fetches and validates the Apple login nonce', () async {
    final api = _FakeAuthApi(
      const ApiEnvelopeDto<AuthLoginResponseDto>(code: 500, success: false),
      nonceResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: AppleLoginNonceResponseDto(
          nonceId: 'nonce-id',
          nonce: 'raw-nonce',
          expiresInSeconds: 300,
        ),
      ),
    );
    final dataSource = AuthLoginRemoteDataSourceImpl(
      api: api,
      clientAuthorization: 'encoded-client-credentials',
    );

    final result = await dataSource.fetchAppleLoginNonce(
      requestId: 'apple-login-123',
    );

    expect(result.nonceId, 'nonce-id');
    expect(result.nonce, 'raw-nonce');
    expect(result.expiresInSeconds, 300);
    expect(
      api.nonceOptions.headers?['authorization'],
      'Basic encoded-client-credentials',
    );
    expect(
      api.nonceOptions.extra?[NetworkRequestExtras.requestId],
      'apple-login-123',
    );
  });

  test('rejects an invalid Apple login nonce response', () async {
    final dataSource = AuthLoginRemoteDataSourceImpl(
      api: _FakeAuthApi(
        const ApiEnvelopeDto<AuthLoginResponseDto>(code: 500, success: false),
        nonceResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: AppleLoginNonceResponseDto(
            nonceId: '',
            nonce: 'raw-nonce',
            expiresInSeconds: 300,
          ),
        ),
      ),
      clientAuthorization: 'encoded-client-credentials',
    );

    expect(
      () => dataSource.fetchAppleLoginNonce(requestId: 'apple-login-123'),
      throwsA(
        isA<AuthLoginRemoteException>().having(
          (error) => error.kind,
          'kind',
          AuthLoginRemoteErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('fetches and validates the Google login nonce', () async {
    final api = _FakeAuthApi(
      const ApiEnvelopeDto<AuthLoginResponseDto>(code: 500, success: false),
      googleNonceResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: GoogleLoginNonceResponseDto(
          nonceId: 'google-nonce-id',
          nonce: 'google-raw-nonce',
          expiresInSeconds: 300,
        ),
      ),
    );
    final dataSource = AuthLoginRemoteDataSourceImpl(
      api: api,
      clientAuthorization: 'encoded-client-credentials',
    );

    final result = await dataSource.fetchGoogleLoginNonce(
      requestId: 'google-login-123',
    );

    expect(result.nonceId, 'google-nonce-id');
    expect(result.nonce, 'google-raw-nonce');
    expect(result.expiresInSeconds, 300);
    expect(
      api.nonceOptions.headers?['authorization'],
      'Basic encoded-client-credentials',
    );
    expect(
      api.nonceOptions.extra?[NetworkRequestExtras.requestId],
      'google-login-123',
    );
  });

  test('fetches and validates the Facebook login nonce', () async {
    final api = _FakeAuthApi(
      const ApiEnvelopeDto<AuthLoginResponseDto>(code: 500, success: false),
      facebookNonceResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: FacebookLoginNonceResponseDto(
          nonceId: 'facebook-nonce-id',
          nonce: 'facebook-raw-nonce',
          expiresInSeconds: 300,
        ),
      ),
    );
    final dataSource = AuthLoginRemoteDataSourceImpl(
      api: api,
      clientAuthorization: 'encoded-client-credentials',
    );

    final result = await dataSource.fetchFacebookLoginNonce(
      requestId: 'facebook-login-123',
    );

    expect(result.nonceId, 'facebook-nonce-id');
    expect(result.nonce, 'facebook-raw-nonce');
    expect(result.expiresInSeconds, 300);
    expect(
      api.nonceOptions.headers?['authorization'],
      'Basic encoded-client-credentials',
    );
    expect(
      api.nonceOptions.extra?[NetworkRequestExtras.requestId],
      'facebook-login-123',
    );
  });

  test('rejects an invalid Facebook login nonce response', () async {
    final dataSource = AuthLoginRemoteDataSourceImpl(
      api: _FakeAuthApi(
        const ApiEnvelopeDto<AuthLoginResponseDto>(code: 500, success: false),
        facebookNonceResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: FacebookLoginNonceResponseDto(
            nonceId: 'facebook-nonce-id',
            nonce: '',
            expiresInSeconds: 300,
          ),
        ),
      ),
      clientAuthorization: 'encoded-client-credentials',
    );

    expect(
      () => dataSource.fetchFacebookLoginNonce(requestId: 'facebook-login-123'),
      throwsA(
        isA<AuthLoginRemoteException>().having(
          (error) => error.kind,
          'kind',
          AuthLoginRemoteErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('submits the complete Apple login request', () async {
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

    final result = await dataSource.loginWithApple(
      request: const {
        'nonceId': 'nonce-id',
        'identityToken': 'header.payload.signature',
        'authorizationCode': 'authorization-code',
        'givenName': 'Alice',
        'familyName': 'Smith',
        'deviceId': 'installation-id',
        'deviceModel': 'iPhone17,2',
        'platform': 'IOS',
        'appVersion': '1.0.0',
      },
      requestId: 'apple-login-123',
    );

    expect(api.body, {
      'nonceId': 'nonce-id',
      'identityToken': 'header.payload.signature',
      'authorizationCode': 'authorization-code',
      'givenName': 'Alice',
      'familyName': 'Smith',
      'deviceId': 'installation-id',
      'deviceModel': 'iPhone17,2',
      'platform': 'IOS',
      'appVersion': '1.0.0',
    });
    expect(
      api.loginOptions.headers?['authorization'],
      'Basic encoded-client-credentials',
    );
    expect(
      api.loginOptions.extra?[NetworkRequestExtras.requestId],
      'apple-login-123',
    );
    expect(result.login.accessToken, 'access-token');
    expect(result.profile.userId, '2');
  });

  test('submits the complete Google login request', () async {
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

    final result = await dataSource.loginWithGoogle(
      request: const {
        'nonceId': 'google-nonce-id',
        'idToken': 'header.payload.signature',
        'authorizationCode': 'authorization-code',
        'deviceId': 'installation-id',
        'deviceModel': 'iPhone17,2',
        'platform': 'IOS',
        'appVersion': '1.0.0',
      },
      requestId: 'google-login-123',
    );

    expect(api.body, {
      'nonceId': 'google-nonce-id',
      'idToken': 'header.payload.signature',
      'authorizationCode': 'authorization-code',
      'deviceId': 'installation-id',
      'deviceModel': 'iPhone17,2',
      'platform': 'IOS',
      'appVersion': '1.0.0',
    });
    expect(
      api.loginOptions.headers?['authorization'],
      'Basic encoded-client-credentials',
    );
    expect(
      api.loginOptions.extra?[NetworkRequestExtras.requestId],
      'google-login-123',
    );
    expect(result.login.accessToken, 'access-token');
    expect(result.profile.userId, '2');
  });

  test('submits the complete Facebook login request', () async {
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

    final result = await dataSource.loginWithFacebook(
      request: const {
        'nonceId': 'facebook-nonce-id',
        'authenticationToken': 'jwt-token',
        'deviceId': 'installation-id',
        'deviceModel': 'iPhone17,2',
        'platform': 'IOS',
        'appVersion': '1.0.0',
      },
      requestId: 'facebook-login-123',
    );

    expect(api.body, {
      'nonceId': 'facebook-nonce-id',
      'authenticationToken': 'jwt-token',
      'deviceId': 'installation-id',
      'deviceModel': 'iPhone17,2',
      'platform': 'IOS',
      'appVersion': '1.0.0',
    });
    expect(
      api.loginOptions.headers?['authorization'],
      'Basic encoded-client-credentials',
    );
    expect(
      api.loginOptions.extra?[NetworkRequestExtras.requestId],
      'facebook-login-123',
    );
    expect(result.login.accessToken, 'access-token');
    expect(result.profile.userId, '2');
  });

  test('rejects a non-200 business response code', () async {
    final dataSource = AuthLoginRemoteDataSourceImpl(
      api: _FakeAuthApi(
        const ApiEnvelopeDto<AuthLoginResponseDto>(
          code: 400,
          success: true,
          msg: 'Account is unavailable.',
        ),
      ),
      clientAuthorization: 'encoded-client-credentials',
    );

    expect(
      () => dataSource.login(requestId: 'login-123', request: const {}),
      throwsA(
        isA<AuthLoginRemoteException>()
            .having(
              (error) => error.kind,
              'kind',
              AuthLoginRemoteErrorKind.businessFailure,
            )
            .having(
              (error) => error.businessFailure?.message,
              'message',
              'Account is unavailable.',
            ),
      ),
    );
  });

  test('preserves HTTP 400 response fields on the network error', () async {
    final requestOptions = RequestOptions(path: 'app/auth/login');
    final dataSource = AuthLoginRemoteDataSourceImpl(
      api: _FakeAuthApi(
        const ApiEnvelopeDto<AuthLoginResponseDto>(code: 500, success: false),
        loginError: DioException.badResponse(
          statusCode: 400,
          requestOptions: requestOptions,
          response: Response<dynamic>(
            requestOptions: requestOptions,
            statusCode: 400,
            data: const {
              'code': 100001,
              'success': false,
              'data': <String, dynamic>{},
              'msg': 'Account or password error.',
              'messageKey': 'account_or_password_error',
            },
          ),
        ),
      ),
      clientAuthorization: 'encoded-client-credentials',
    );

    await expectLater(
      dataSource.login(requestId: 'login-123', request: const {}),
      throwsA(
        isA<AuthLoginRemoteException>()
            .having(
              (error) => error.kind,
              'kind',
              AuthLoginRemoteErrorKind.network,
            )
            .having(
              (error) => error.network?.businessCode,
              'business code',
              100001,
            )
            .having(
              (error) => error.network?.userMessage,
              'message',
              'Account or password error.',
            )
            .having(
              (error) => error.network?.businessMessageKey,
              'message key',
              'account_or_password_error',
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
          AuthLoginRemoteErrorKind.businessFailure,
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
    this.nonceResponse = const ApiEnvelopeDto(
      code: 200,
      success: true,
      data: AppleLoginNonceResponseDto(
        nonceId: 'nonce-id',
        nonce: 'raw-nonce',
        expiresInSeconds: 300,
      ),
    ),
    this.googleNonceResponse = const ApiEnvelopeDto(
      code: 200,
      success: true,
      data: GoogleLoginNonceResponseDto(
        nonceId: 'google-nonce-id',
        nonce: 'google-raw-nonce',
        expiresInSeconds: 300,
      ),
    ),
    this.facebookNonceResponse = const ApiEnvelopeDto(
      code: 200,
      success: true,
      data: FacebookLoginNonceResponseDto(
        nonceId: 'facebook-nonce-id',
        nonce: 'facebook-raw-nonce',
        expiresInSeconds: 300,
      ),
    ),
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
    this.loginError,
  });

  final ApiEnvelopeDto<AuthLoginResponseDto> response;
  final ApiEnvelopeDto<AppleLoginNonceResponseDto> nonceResponse;
  final ApiEnvelopeDto<GoogleLoginNonceResponseDto> googleNonceResponse;
  final ApiEnvelopeDto<FacebookLoginNonceResponseDto> facebookNonceResponse;
  final ApiEnvelopeDto<AuthProfileResponseDto> profileResponse;
  final DioException? loginError;
  late Map<String, dynamic> body;
  late Options loginOptions;
  late Options nonceOptions;
  late Options profileOptions;

  @override
  Future<ApiEnvelopeDto<AuthLoginResponseDto>> login(
    Map<String, dynamic> requestBody,
    Options requestOptions,
  ) async {
    body = requestBody;
    loginOptions = requestOptions;
    final error = loginError;
    if (error != null) throw error;
    return response;
  }

  @override
  Future<ApiEnvelopeDto<AuthLoginResponseDto>> loginWithApple(
    Map<String, dynamic> requestBody,
    Options requestOptions,
  ) async {
    body = requestBody;
    loginOptions = requestOptions;
    return response;
  }

  @override
  Future<ApiEnvelopeDto<AuthLoginResponseDto>> loginWithGoogle(
    Map<String, dynamic> requestBody,
    Options requestOptions,
  ) async {
    body = requestBody;
    loginOptions = requestOptions;
    return response;
  }

  @override
  Future<ApiEnvelopeDto<AuthLoginResponseDto>> loginWithFacebook(
    Map<String, dynamic> requestBody,
    Options requestOptions,
  ) async {
    body = requestBody;
    loginOptions = requestOptions;
    return response;
  }

  @override
  Future<ApiEnvelopeDto<AppleLoginNonceResponseDto>> fetchAppleLoginNonce(
    Options requestOptions,
  ) async {
    nonceOptions = requestOptions;
    return nonceResponse;
  }

  @override
  Future<ApiEnvelopeDto<GoogleLoginNonceResponseDto>> fetchGoogleLoginNonce(
    Options requestOptions,
  ) async {
    nonceOptions = requestOptions;
    return googleNonceResponse;
  }

  @override
  Future<ApiEnvelopeDto<FacebookLoginNonceResponseDto>> fetchFacebookLoginNonce(
    Options requestOptions,
  ) async {
    nonceOptions = requestOptions;
    return facebookNonceResponse;
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
