import '../entities/operation_record_page_result.dart';

/// 操作记录的分页查询接口。
abstract interface class OperationRecordRepository {
  Future<OperationRecordPageResult> fetchOperationRecords({
    required String doorId,
    required int page,
    required int pageSize,
    required String requestId,
  });
}
