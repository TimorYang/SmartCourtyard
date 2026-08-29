import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../../domain/entities/registration_verification.dart';
import 'auth_api.dart';

abstract interface class AuthRegistrationRemoteDataSource {
  Future<void> sendEmailCode({
    required String email,
    required String requestId,
  });
  Future<RegistrationVerification> verifyEmailCode({
    required String email,
    required String code,
    required String requestId,
  });
  Future<void> completeRegistration({
    required Map<String, dynamic> request,
    required String requestId,
  });
}

class AuthRegistrationRemoteDataSourceImpl
    implements AuthRegistrationRemoteDataSource {
  AuthRegistrationRemoteDataSourceImpl({
    required this.api,
    required this.clientAuthorization,
  });

  final AuthApi api;
  final String clientAuthorization;

  Options _options(String requestId) {
    if (clientAuthorization.trim().isEmpty) {
      throw const AuthRegistrationRemoteException.configuration();
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
      final response = await api.sendRegistrationEmailCode({
        'email': email,
      }, _options(requestId));
      if (response.code != 200 || !response.success || response.data != true) {
        throw const AuthRegistrationRemoteException.invalidResponse();
      }
    } on DioException catch (error) {
      throw AuthRegistrationRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on AuthRegistrationRemoteException {
      rethrow;
    }
  }

  @override
  Future<RegistrationVerification> verifyEmailCode({
    required String email,
    required String code,
    required String requestId,
  }) async {
    try {
      final response = await api.verifyRegistrationEmailCode({
        'email': email,
        'code': int.parse(code),
      }, _options(requestId));
      final data = response.data;
      if (response.code != 200 || !response.success || data is! Map) {
        throw const AuthRegistrationRemoteException.invalidResponse();
      }
      final token = data['registrationToken'];
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
        throw const AuthRegistrationRemoteException.invalidResponse();
      }
      return RegistrationVerification(
        registrationToken: token,
        expiresIn: Duration(seconds: expiresInSeconds),
      );
    } on DioException catch (error) {
      throw AuthRegistrationRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on AuthRegistrationRemoteException {
      rethrow;
    } on FormatException {
      throw const AuthRegistrationRemoteException.invalidResponse();
    }
  }

  @override
  Future<void> completeRegistration({
    required Map<String, dynamic> request,
    required String requestId,
  }) async {
    try {
      final response = await api.completeRegistration(
        request,
        _options(requestId),
      );
      if (response.code != 200 || !response.success || response.data != true) {
        throw const AuthRegistrationRemoteException.invalidResponse();
      }
    } on DioException catch (error) {
      throw AuthRegistrationRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on AuthRegistrationRemoteException {
      rethrow;
    }
  }
}

class AuthRegistrationRemoteException implements Exception {
  const AuthRegistrationRemoteException._(this.kind, {this.statusCode});
  const AuthRegistrationRemoteException.configuration()
    : this._(AuthRegistrationRemoteErrorKind.configuration);
  AuthRegistrationRemoteException.fromNetwork(NetworkException exception)
    : this._(
        AuthRegistrationRemoteErrorKind.network,
        statusCode: exception.statusCode,
      );
  const AuthRegistrationRemoteException.invalidResponse()
    : this._(AuthRegistrationRemoteErrorKind.invalidResponse);

  final AuthRegistrationRemoteErrorKind kind;
  final int? statusCode;
}

enum AuthRegistrationRemoteErrorKind { configuration, network, invalidResponse }
