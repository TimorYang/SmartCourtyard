import 'package:dio/dio.dart';

import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/safety_sensors_evaluation_dto.dart';
import 'safety_sensors_evaluation_api.dart';

abstract interface class SafetySensorsEvaluationRemoteDataSource {
  Future<SafetySensorsEvaluationDto> fetchEvaluation({
    required int doorId,
    required String requestId,
  });
}

class SafetySensorsEvaluationRemoteDataSourceImpl
    implements SafetySensorsEvaluationRemoteDataSource {
  const SafetySensorsEvaluationRemoteDataSourceImpl({required this.api});

  final SafetySensorsEvaluationApi api;

  @override
  Future<SafetySensorsEvaluationDto> fetchEvaluation({
    required int doorId,
    required String requestId,
  }) async {
    try {
      final response = await api.fetchEvaluation(
        doorId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if ((response.code != 0 && response.code != 200) || !response.success) {
        throw SafetySensorsEvaluationRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const SafetySensorsEvaluationRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw SafetySensorsEvaluationRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on SafetySensorsEvaluationRemoteException {
      rethrow;
    }
  }
}

class SafetySensorsEvaluationRemoteException implements Exception {
  const SafetySensorsEvaluationRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  SafetySensorsEvaluationRemoteException.fromNetwork(NetworkException error)
    : this._(SafetySensorsEvaluationRemoteErrorKind.network, network: error);

  const SafetySensorsEvaluationRemoteException.businessFailure(
    ApiBusinessFailure failure,
  ) : this._(
        SafetySensorsEvaluationRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );

  const SafetySensorsEvaluationRemoteException.invalidResponse()
    : this._(SafetySensorsEvaluationRemoteErrorKind.invalidResponse);

  final SafetySensorsEvaluationRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
}

enum SafetySensorsEvaluationRemoteErrorKind {
  network,
  businessFailure,
  invalidResponse,
}
