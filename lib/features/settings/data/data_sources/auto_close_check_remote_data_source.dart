import 'package:dio/dio.dart';

import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/auto_close_check_response_dto.dart';
import 'auto_close_check_api.dart';

abstract interface class AutoCloseCheckRemoteDataSource {
  Future<AutoCloseCheckResponseDto> checkAutoClose({
    required int doorId,
    required int deviceId,
    required String requestId,
  });
}

class AutoCloseCheckRemoteDataSourceImpl
    implements AutoCloseCheckRemoteDataSource {
  const AutoCloseCheckRemoteDataSourceImpl({required this.api});

  final AutoCloseCheckApi api;

  @override
  Future<AutoCloseCheckResponseDto> checkAutoClose({
    required int doorId,
    required int deviceId,
    required String requestId,
  }) async {
    try {
      final response = await api.checkAutoClose(
        doorId,
        deviceId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!response.isBusinessSuccess) {
        throw AutoCloseCheckRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      final data = response.data;
      if (data == null || data.autoCloseAllowed == null) {
        throw const AutoCloseCheckRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw AutoCloseCheckRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on AutoCloseCheckRemoteException {
      rethrow;
    } on FormatException {
      throw const AutoCloseCheckRemoteException.invalidResponse();
    } on TypeError {
      throw const AutoCloseCheckRemoteException.invalidResponse();
    }
  }
}

class AutoCloseCheckRemoteException implements Exception {
  const AutoCloseCheckRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  AutoCloseCheckRemoteException.fromNetwork(NetworkException exception)
    : this._(AutoCloseCheckRemoteErrorKind.network, network: exception);

  const AutoCloseCheckRemoteException.businessFailure(
    ApiBusinessFailure failure,
  ) : this._(
        AutoCloseCheckRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );

  const AutoCloseCheckRemoteException.invalidResponse()
    : this._(AutoCloseCheckRemoteErrorKind.invalidResponse);

  final AutoCloseCheckRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
}

enum AutoCloseCheckRemoteErrorKind { network, businessFailure, invalidResponse }
