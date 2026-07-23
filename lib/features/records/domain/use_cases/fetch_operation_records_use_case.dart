import '../entities/operation_record_page_result.dart';
import '../repositories/operation_record_repository.dart';

class FetchOperationRecordsUseCase {
  const FetchOperationRecordsUseCase({required this.repository});

  final OperationRecordRepository repository;

  Future<OperationRecordPageResult> call({
    required String doorId,
    required int page,
    required int pageSize,
    required String requestId,
  }) {
    return repository.fetchOperationRecords(
      doorId: doorId,
      page: page,
      pageSize: pageSize,
      requestId: requestId,
    );
  }
}
