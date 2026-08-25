import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/apple_login_nonce_response_dto.dart';
import '../dto/auth_login_response_dto.dart';
import '../dto/auth_profile_response_dto.dart';
import 'auth_api.dart';

abstract interface class AuthLoginRemoteDataSource {
  Future<AuthLoginRemoteResult> login({
    required Map<String, dynamic> request,
    required String requestId,
  });

  Future<AuthLoginRemoteResult> loginWithApple({
    required Map<String, dynamic> request,
    required String requestId,
  });

  Future<AppleLoginNonceResponseDto> fetchAppleLoginNonce({
    required String requestId,
  });
}

class AuthLoginRemoteDataSourceImpl implements AuthLoginRemoteDataSource {
  AuthLoginRemoteDataSourceImpl({
    required this.api,
    required this.clientAuthorization,
  });

  final AuthApi api;
  final String clientAuthorization;

  @override
  Future<AuthLoginRemoteResult> login({
    required Map<String, dynamic> request,
    required String requestId,
  }) async {
    return _performLogin(
      requestId: requestId,
      request: request,
      submit: api.login,
    );
  }

  @override
  Future<AuthLoginRemoteResult> loginWithApple({
    required Map<String, dynamic> request,
    required String requestId,
  }) async {
    return _performLogin(
      requestId: requestId,
      request: request,
      submit: api.loginWithApple,
    );
  }

  @override
  Future<AppleLoginNonceResponseDto> fetchAppleLoginNonce({
    required String requestId,
  }) async {
    _validateConfiguration();
    try {
      final response = await api.fetchAppleLoginNonce(
        _authorizationOptions(requestId),
      );
      final data = response.data;
      if ((response.code != 0 && response.code != 200) ||
          !response.success ||
          data == null ||
          data.nonceId.trim().isEmpty ||
          data.nonce.trim().isEmpty ||
          data.expiresInSeconds <= 0) {
        throw const AuthLoginRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw AuthLoginRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on AuthLoginRemoteException {
      rethrow;
    }
  }

  Future<AuthLoginRemoteResult> _performLogin({
    required String requestId,
    required Map<String, dynamic> request,
    required Future<ApiEnvelopeDto<AuthLoginResponseDto>> Function(
      Map<String, dynamic>,
      Options,
    )
    submit,
  }) async {
    _validateConfiguration();
    try {
      final response = await submit(request, _authorizationOptions(requestId));
      final data = response.data;
      if ((response.code != 0 && response.code != 200) ||
          !response.success ||
          data == null ||
          !_hasUsableTokens(data)) {
        throw const AuthLoginRemoteException.invalidResponse();
      }
      final profileResponse = await api.fetchAccountProfile(
        Options(
          headers: {'Blade-Auth': data.accessToken},
          extra: {
            NetworkRequestExtras.requestId: requestId,
            NetworkRequestExtras.skipTokenRefresh: true,
          },
        ),
      );
      final profile = profileResponse.data;
      if ((profileResponse.code != 0 && profileResponse.code != 200) ||
          !profileResponse.success ||
          profile == null ||
          !_hasProfile(profile)) {
        throw const AuthLoginRemoteException.invalidResponse();
      }
      return AuthLoginRemoteResult(login: data, profile: profile);
    } on DioException catch (error) {
      throw AuthLoginRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on AuthLoginRemoteException {
      rethrow;
    }
  }

  bool _hasUsableTokens(AuthLoginResponseDto data) =>
      data.accessToken.trim().isNotEmpty &&
      data.refreshToken.trim().isNotEmpty &&
      data.tokenType.trim().isNotEmpty &&
      data.expiresInSeconds > 0 &&
      data.refreshExpiresInSeconds > 0;

  bool _hasProfile(AuthProfileResponseDto profile) =>
      profile.userId.trim().isNotEmpty &&
      profile.email.trim().isNotEmpty &&
      profile.nickname.trim().isNotEmpty;

  void _validateConfiguration() {
    if (clientAuthorization.trim().isEmpty) {
      throw const AuthLoginRemoteException.configuration();
    }
  }

  Options _authorizationOptions(String requestId) => Options(
    headers: {'authorization': 'Basic ${clientAuthorization.trim()}'},
    extra: {NetworkRequestExtras.requestId: requestId},
  );
}

class AuthLoginRemoteResult {
  const AuthLoginRemoteResult({required this.login, required this.profile});

  final AuthLoginResponseDto login;
  final AuthProfileResponseDto profile;
}

class AuthLoginRemoteException implements Exception {
  const AuthLoginRemoteException._(this.kind, {this.statusCode});

  const AuthLoginRemoteException.configuration()
    : this._(AuthLoginRemoteErrorKind.configuration);
  AuthLoginRemoteException.fromNetwork(NetworkException exception)
    : this._(
        AuthLoginRemoteErrorKind.network,
        statusCode: exception.statusCode,
      );
  const AuthLoginRemoteException.invalidResponse()
    : this._(AuthLoginRemoteErrorKind.invalidResponse);

  final AuthLoginRemoteErrorKind kind;
  final int? statusCode;
}

enum AuthLoginRemoteErrorKind { configuration, network, invalidResponse }
