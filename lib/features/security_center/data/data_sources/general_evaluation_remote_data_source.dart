import 'package:dio/dio.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/general_evaluation_dtos.dart';
import 'general_evaluation_api.dart';

abstract interface class GeneralEvaluationRemoteDataSource {
  Future<GeneralEvaluationResponseDto> general({
    required int doorId,
    required String requestId,
  });
  Future<BalanceResponseDto> balance({
    required int doorId,
    required String assessmentRequestId,
    required String requestId,
  });
  Future<OperationStatisticsDto> operations({
    required int doorId,
    required int range,
    required String requestId,
  });
}

class GeneralEvaluationRemoteDataSourceImpl
    implements GeneralEvaluationRemoteDataSource {
  const GeneralEvaluationRemoteDataSourceImpl({
    required this.api,
    required this.logger,
  });
  final GeneralEvaluationApi api;
  final AppLogger logger;
  Options _o(String id) => Options(extra: {NetworkRequestExtras.requestId: id});
  bool _ok(int c, bool s, Object? d) => (c == 0 || c == 200) && s && d != null;
  @override
  Future<GeneralEvaluationResponseDto> general({
    required int doorId,
    required String requestId,
  }) => _wrap(
    () => api.general(doorId, _o(requestId)),
    endpoint: 'general',
    requestId: requestId,
  );
  @override
  Future<BalanceResponseDto> balance({
    required int doorId,
    required String assessmentRequestId,
    required String requestId,
  }) => _wrap(
    () => api.balance(doorId, assessmentRequestId, _o(requestId)),
    endpoint: 'balance',
    requestId: requestId,
  );
  @override
  Future<OperationStatisticsDto> operations({
    required int doorId,
    required int range,
    required String requestId,
  }) => _wrap(
    () => api.operations(doorId, range, _o(requestId)),
    endpoint: 'operations',
    range: range,
    requestId: requestId,
  );

  Future<T> _wrap<T>(
    Future<dynamic> Function() call, {
    required String endpoint,
    required String requestId,
    int? range,
  }) async {
    try {
      final r = await call();
      if (!_ok(r.code, r.success, r.data)) {
        logger.warning(
          'General evaluation response failed envelope validation',
          requestId: requestId,
          context: {
            'endpoint': endpoint,
            'range': range,
            'code': r.code,
            'success': r.success,
            'hasData': r.data != null,
            'dataType': r.data?.runtimeType.toString(),
          },
        );
        throw const GeneralEvaluationRemoteException.invalidResponse();
      }
      return r.data as T;
    } on DioException catch (e) {
      logger.warning(
        'General evaluation request failed before envelope validation',
        requestId: requestId,
        context: {
          'endpoint': endpoint,
          'range': range,
          'dioErrorType': e.type.name,
          'statusCode': e.response?.statusCode,
        },
      );
      throw GeneralEvaluationRemoteException.fromNetwork(
        NetworkException.fromDio(e),
      );
    } on GeneralEvaluationRemoteException {
      rethrow;
    }
  }
}

class GeneralEvaluationRemoteException implements Exception {
  const GeneralEvaluationRemoteException._(this.kind);
  GeneralEvaluationRemoteException.fromNetwork(NetworkException e)
    : this._(GeneralEvaluationRemoteErrorKind.network);
  const GeneralEvaluationRemoteException.invalidResponse()
    : this._(GeneralEvaluationRemoteErrorKind.invalidResponse);
  final GeneralEvaluationRemoteErrorKind kind;
}

enum GeneralEvaluationRemoteErrorKind { network, invalidResponse }
