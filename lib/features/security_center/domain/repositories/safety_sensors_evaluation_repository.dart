import '../entities/safety_sensors_evaluation.dart';

abstract interface class SafetySensorsEvaluationRepository {
  Future<SafetySensorsEvaluation> fetchEvaluation({
    required String doorId,
    required String requestId,
  });
}
