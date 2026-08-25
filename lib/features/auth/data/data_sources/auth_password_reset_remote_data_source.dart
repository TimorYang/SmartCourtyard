import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../../domain/entities/password_reset_verification.dart';
import 'auth_api.dart';

abstract interface class AuthPasswordResetRemoteDataSource {
  Future<void> sendEmailCode({
    required String email,
    required String requestId,
  });

  Future<PasswordResetVerification> verifyEmailCode({
    required String email,
    required String code,
    required String requestId,
  });

  Future<void> completePasswordReset({
    required Map<String, dynamic> request,
    required String requestId,
  });
}

class AuthPasswordResetRemoteDataSourceImpl
    implements AuthPasswordResetRemoteDataSource {
  AuthPasswordResetRemoteDataSourceImpl({
    required this.api,
    required this.clientAuthorization,
  });

  final AuthApi api;
  final String clientAuthorization;

  Options _options(String requestId) {
    if (clientAuthorization.trim().isEmpty) {
      throw const AuthPasswordResetRemoteException.configuration();
    }
    return Options(
      headers: {'authorization': 'Basic ${clientAuthorization.trim()}'},
      extra: {NetworkRequestExtras.requestId: requestId},
    );
  }

  @override
  Future<void> sendEmailCode({
    required String email,
    required String requestId,
  }) async {
    try {
      final response = await api.sendPasswordResetEmailCode({
        'email': email,
      }, _options(requestId));
      _validateEnvelope(response.code, response.success);
    } on DioException catch (error) {
      throw AuthPasswordResetRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on AuthPasswordResetRemoteException {
      rethrow;
    }
  }

  @override
  Future<PasswordResetVerification> verifyEmailCode({
    required String email,
    required String code,
    required String requestId,
  }) async {
    try {
      final response = await api.verifyPasswordResetEmailCode({
        'email': email,
        'code': code,
      }, _options(requestId));
      _validateEnvelope(response.code, response.success);
      final data = response.data;
      if (data is! Map) {
        throw const AuthPasswordResetRemoteException.invalidResponse();
      }
      final token = data['passwordResetToken'];
      final expiresIn = data['expiresIn'];
      final expiresInSeconds = switch (expiresIn) {
        final num value => value.toInt(),
        final String value => int.tryParse(value.trim()),
        _ => null,
      };
      if (token is! String ||
          token.isEmpty ||
          expiresInSeconds == null ||
          expiresInSeconds <= 0) {
        throw const AuthPasswordResetRemoteException.invalidResponse();
      }
      return PasswordResetVerification(
        passwordResetToken: token,
        expiresIn: Duration(seconds: expiresInSeconds),
      );
    } on DioException catch (error) {
      throw AuthPasswordResetRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on AuthPasswordResetRemoteException {
      rethrow;
    }
  }

  @override
  Future<void> completePasswordReset({
    required Map<String, dynamic> request,
    required String requestId,
  }) async {
    try {
      final response = await api.completePasswordReset(
        request,
        _options(requestId),
      );
      _validateEnvelope(response.code, response.success);
    } on DioException catch (error) {
      throw AuthPasswordResetRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on AuthPasswordResetRemoteException {
      rethrow;
    }
  }

  void _validateEnvelope(int code, bool success) {
    if ((code != 0 && code != 200) || !success) {
      throw const AuthPasswordResetRemoteException.invalidResponse();
    }
  }
}

class AuthPasswordResetRemoteException implements Exception {
  const AuthPasswordResetRemoteException._(this.kind, {this.statusCode});

  const AuthPasswordResetRemoteException.configuration()
    : this._(AuthPasswordResetRemoteErrorKind.configuration);

  AuthPasswordResetRemoteException.fromNetwork(NetworkException exception)
    : this._(
        AuthPasswordResetRemoteErrorKind.network,
        statusCode: exception.statusCode,
      );

  const AuthPasswordResetRemoteException.invalidResponse()
    : this._(AuthPasswordResetRemoteErrorKind.invalidResponse);

  final AuthPasswordResetRemoteErrorKind kind;
  final int? statusCode;
}

enum AuthPasswordResetRemoteErrorKind {
  configuration,
  network,
  invalidResponse,
}
