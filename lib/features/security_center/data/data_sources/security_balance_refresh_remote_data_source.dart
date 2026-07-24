import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/security_balance_refresh_response_dto.dart';
import 'security_balance_refresh_api.dart';

abstract interface class SecurityBalanceRefreshRemoteDataSource {
  Future<SecurityBalanceRefreshResponseDto> refreshBalance({
    required int doorId,
    required String requestId,
  });
}

class SecurityBalanceRefreshRemoteDataSourceImpl
    implements SecurityBalanceRefreshRemoteDataSource {
  const SecurityBalanceRefreshRemoteDataSourceImpl({required this.api});

  final SecurityBalanceRefreshApi api;

  @override
  Future<SecurityBalanceRefreshResponseDto> refreshBalance({
    required int doorId,
    required String requestId,
  }) async {
    try {
      final response = await api.refreshBalance(
        doorId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (response.code != 0 && response.code != 200) {
        throw const SecurityBalanceRefreshRemoteException.invalidResponse();
      }
      return response.data ?? const SecurityBalanceRefreshResponseDto();
    } on DioException catch (error) {
      throw SecurityBalanceRefreshRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on SecurityBalanceRefreshRemoteException {
      rethrow;
    }
  }
}

class SecurityBalanceRefreshRemoteException implements Exception {
  const SecurityBalanceRefreshRemoteException._(this.kind, {this.statusCode});

  SecurityBalanceRefreshRemoteException.fromNetwork(NetworkException exception)
    : this._(
        SecurityBalanceRefreshRemoteErrorKind.network,
        statusCode: exception.statusCode,
      );

  const SecurityBalanceRefreshRemoteException.invalidResponse()
    : this._(SecurityBalanceRefreshRemoteErrorKind.invalidResponse);

  final SecurityBalanceRefreshRemoteErrorKind kind;
  final int? statusCode;
}

enum SecurityBalanceRefreshRemoteErrorKind { network, invalidResponse }
