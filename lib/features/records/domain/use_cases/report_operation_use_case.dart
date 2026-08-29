import '../repositories/operation_record_repository.dart';

class ReportOperationUseCase {
  const ReportOperationUseCase({required this.repository});

  final OperationRecordRepository repository;

  Future<void> call({
    required String doorId,
    required OperationReportAction action,
    required OperationReportSource operationSource,
    required String requestId,
  }) {
    return repository.reportOperation(
      doorId: doorId,
      action: action,
      operationSource: operationSource,
      requestId: requestId,
    );
  }
}
