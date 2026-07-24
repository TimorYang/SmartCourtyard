import '../entities/general_evaluation_report.dart';
import '../repositories/general_evaluation_repository.dart';

class FetchGeneralEvaluationUseCase {
  const FetchGeneralEvaluationUseCase({required this.repository});
  final GeneralEvaluationRepository repository;
  Future<GeneralEvaluationReport> call({
    required String doorId,
    String? assessmentRequestId,
    required String requestId,
  }) => repository.fetch(
    doorId: doorId,
    assessmentRequestId: assessmentRequestId,
    requestId: requestId,
  );
}
