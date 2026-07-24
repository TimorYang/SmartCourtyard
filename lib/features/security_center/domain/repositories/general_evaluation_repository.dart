import '../entities/general_evaluation_report.dart';

abstract interface class GeneralEvaluationRepository {
  Future<GeneralEvaluationReport> fetch({
    required String doorId,
    String? assessmentRequestId,
    required String requestId,
  });
}
