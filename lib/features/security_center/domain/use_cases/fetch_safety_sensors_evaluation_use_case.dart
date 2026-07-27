import '../entities/safety_sensors_evaluation.dart';
import '../repositories/safety_sensors_evaluation_repository.dart';

class FetchSafetySensorsEvaluationUseCase {
  const FetchSafetySensorsEvaluationUseCase({required this.repository});

  final SafetySensorsEvaluationRepository repository;

  Future<SafetySensorsEvaluation> call({
    required String doorId,
    required String requestId,
  }) => repository.fetchEvaluation(doorId: doorId, requestId: requestId);
}
