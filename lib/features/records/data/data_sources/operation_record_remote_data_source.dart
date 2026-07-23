import 'package:dio/dio.dart';

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
      if (!_isSuccessCode(response.code) || !response.success || data == null) {
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
  const OperationRecordRemoteException._(this.kind, {this.statusCode});

  OperationRecordRemoteException.fromNetwork(NetworkException exception)
    : this._(
        OperationRecordRemoteErrorKind.network,
        statusCode: exception.statusCode,
      );

  const OperationRecordRemoteException.invalidResponse()
    : this._(OperationRecordRemoteErrorKind.invalidResponse);

  final OperationRecordRemoteErrorKind kind;
  final int? statusCode;
}

enum OperationRecordRemoteErrorKind { network, invalidResponse }
