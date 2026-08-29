export '../entities/operation_report.dart';

import '../entities/operation_report.dart';
import '../entities/operation_record_page_result.dart';

/// 操作记录的分页查询接口。
abstract interface class OperationRecordRepository {
  Future<void> reportOperation({
    required String doorId,
    required OperationReportAction action,
    required OperationReportSource operationSource,
    required String requestId,
  });

  Future<OperationRecordPageResult> fetchOperationRecords({
    required String doorId,
    required int page,
    required int pageSize,
    required String requestId,
  });
}
