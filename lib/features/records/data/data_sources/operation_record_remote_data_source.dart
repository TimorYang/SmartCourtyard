import 'package:dio/dio.dart';

import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/operation_report_request_dto.dart';
import '../dto/operation_record_response_dto.dart';
import 'operation_record_api.dart';

abstract interface class OperationRecordRemoteDataSource {
  Future<void> reportOperation({
    required int doorId,
    required OperationReportRequestDto body,
    required String requestId,
  });

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
  Future<void> reportOperation({
    required int doorId,
    required OperationReportRequestDto body,
    required String requestId,
  }) async {
    try {
      final response = await api.reportOperation(
        doorId,
        body,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      _validateReportResponse(response);
    } on DioException catch (error) {
      throw OperationRecordRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on OperationRecordRemoteException {
      rethrow;
    } on Object {
      throw const OperationRecordRemoteException.invalidResponse();
    }
  }

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
      if (!response.isBusinessSuccess) {
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

  void _validateReportResponse(ApiEnvelopeDto<bool> response) {
    if (!response.isBusinessSuccess) {
      throw OperationRecordRemoteException.businessFailure(
        ApiBusinessFailure.fromEnvelope(response),
      );
    }
    if (response.data != true) {
      throw const OperationRecordRemoteException.invalidResponse();
    }
  }
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
