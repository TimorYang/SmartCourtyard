import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/auth_login_response_dto.dart';
import '../dto/auth_profile_response_dto.dart';
import 'auth_api.dart';

abstract interface class AuthLoginRemoteDataSource {
  Future<AuthLoginRemoteResult> login({
    required Map<String, dynamic> request,
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
    if (clientAuthorization.trim().isEmpty) {
      throw const AuthLoginRemoteException.configuration();
    }
    try {
      final response = await api.login(
        request,
        Options(
          headers: {'authorization': 'Basic ${clientAuthorization.trim()}'},
          extra: {NetworkRequestExtras.requestId: requestId},
        ),
      );
      // The login endpoint's business contract defines code 200 as success.
      final data = response.data;
      if (response.code != 200 ||
          !response.success ||
          data == null ||
          !_hasUsableTokens(data)) {
        throw const AuthLoginRemoteException.invalidResponse();
      }
      final profileResponse = await api.fetchAccountProfile(
        Options(
          headers: {'Blade-Auth': data.accessToken},
          extra: {NetworkRequestExtras.requestId: requestId},
        ),
      );
      final profile = profileResponse.data;
      if (profileResponse.code != 200 ||
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
      data.expiresInSeconds > 0;

  bool _hasProfile(AuthProfileResponseDto profile) =>
      profile.userId.trim().isNotEmpty &&
      profile.email.trim().isNotEmpty &&
      profile.nickname.trim().isNotEmpty;
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
