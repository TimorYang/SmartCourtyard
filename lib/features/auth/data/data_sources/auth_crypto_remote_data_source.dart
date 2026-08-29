import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/auth_public_key_response_dto.dart';
import 'auth_api.dart';

abstract interface class AuthCryptoRemoteDataSource {
  Future<AuthPublicKeyResponseDto> fetchPublicKeyAndNonce({
    required String requestId,
  });
}

class AuthCryptoRemoteDataSourceImpl implements AuthCryptoRemoteDataSource {
  AuthCryptoRemoteDataSourceImpl({
    required this.api,
    required this.clientAuthorization,
  });

  final AuthApi api;
  final String clientAuthorization;

  @override
  Future<AuthPublicKeyResponseDto> fetchPublicKeyAndNonce({
    required String requestId,
  }) async {
    if (clientAuthorization.trim().isEmpty) {
      throw const AuthCryptoRemoteException.configuration();
    }
    try {
      final response = await api.fetchPublicKey(
        Options(
          headers: {'authorization': 'Basic $clientAuthorization'},
          extra: {NetworkRequestExtras.requestId: requestId},
        ),
      );
      final data = response.data;
      if (response.code != 200 || !response.success) {
        throw AuthCryptoRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const AuthCryptoRemoteException.invalidResponse();
      }
      _validate(data);
      return data;
    } on DioException catch (error) {
      throw AuthCryptoRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on AuthCryptoRemoteException {
      rethrow;
    } on FormatException catch (_) {
      throw const AuthCryptoRemoteException.invalidResponse();
    }
  }

  void _validate(AuthPublicKeyResponseDto data) {
    if (data.keyId.isEmpty ||
        data.algorithm != 'RSA-OAEP-256' ||
        data.publicKey.isEmpty ||
        data.nonce.isEmpty ||
        data.expiresInSeconds <= 0) {
      throw const AuthCryptoRemoteException.invalidResponse();
    }
  }
}

class AuthCryptoRemoteException implements Exception {
  const AuthCryptoRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  const AuthCryptoRemoteException.configuration()
    : this._(AuthCryptoRemoteErrorKind.configuration);
  const AuthCryptoRemoteException.network()
    : this._(AuthCryptoRemoteErrorKind.network);
  AuthCryptoRemoteException.fromNetwork(NetworkException exception)
    : this._(AuthCryptoRemoteErrorKind.network, network: exception);
  AuthCryptoRemoteException.businessFailure(ApiBusinessFailure failure)
    : this._(
        AuthCryptoRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );
  const AuthCryptoRemoteException.invalidResponse()
    : this._(AuthCryptoRemoteErrorKind.invalidResponse);

  final AuthCryptoRemoteErrorKind kind;
  final NetworkException? network;
  int? get statusCode => network?.statusCode;
  final ApiBusinessFailure? businessFailure;
}

enum AuthCryptoRemoteErrorKind {
  configuration,
  network,
  businessFailure,
  invalidResponse,
}
