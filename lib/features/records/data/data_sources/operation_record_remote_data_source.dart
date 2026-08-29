import 'package:dio/dio.dart';

import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/operation_record_response_dto.dart';
import 'operation_record_api.dart';

abstract interface class OperationRecordRemoteDataSource {
  Future<OperationRecordPageResponseDto> fetchOperationRecords({
    required int doorId,
    required int page,
    required int pageSize,
    required String requestId,
  });
}

class OperationRecordRemoteDataSourceImpl
    implements OperationRecordRemoteDataSource {
  const OperationRecordRemoteDataSourceImpl({required this.api});

  final OperationRecordApi api;

  @override
  Future<OperationRecordPageResponseDto> fetchOperationRecords({
    required int doorId,
    required int page,
    required int pageSize,
    required String requestId,
  }) async {
    try {
      final response = await api.fetchOperationRecords(
        doorId,
        page,
        pageSize,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (!_isSuccessCode(response.code) || !response.success) {
        throw OperationRecordRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const OperationRecordRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw OperationRecordRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on OperationRecordRemoteException {
      rethrow;
    }
  }

  bool _isSuccessCode(int code) => code == 0 || code == 200;
}

class OperationRecordRemoteException implements Exception {
  const OperationRecordRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  OperationRecordRemoteException.fromNetwork(NetworkException exception)
    : this._(OperationRecordRemoteErrorKind.network, network: exception);

  const OperationRecordRemoteException.businessFailure(
    ApiBusinessFailure failure,
  ) : this._(
        OperationRecordRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );

  const OperationRecordRemoteException.invalidResponse()
    : this._(OperationRecordRemoteErrorKind.invalidResponse);

  final OperationRecordRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  int? get statusCode => network?.statusCode;
}

enum OperationRecordRemoteErrorKind {
  network,
  businessFailure,
  invalidResponse,
}
