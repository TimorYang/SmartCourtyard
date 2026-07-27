import 'package:dio/dio.dart';

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
      if ((response.code != 0 && response.code != 200) ||
          !response.success ||
          data == null) {
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
  const SafetySensorsEvaluationRemoteException._(this.kind);

  SafetySensorsEvaluationRemoteException.fromNetwork(NetworkException error)
    : this._(SafetySensorsEvaluationRemoteErrorKind.network);

  const SafetySensorsEvaluationRemoteException.invalidResponse()
    : this._(SafetySensorsEvaluationRemoteErrorKind.invalidResponse);

  final SafetySensorsEvaluationRemoteErrorKind kind;
}

enum SafetySensorsEvaluationRemoteErrorKind { network, invalidResponse }
