import 'operation_record.dart';

/// 一页操作记录的查询结果。
class OperationRecordPageResult {
  const OperationRecordPageResult({
    required this.records,
    required this.currentPage,
    required this.hasMore,
  });

  final List<OperationRecord> records;
  final int currentPage;
  final bool hasMore;
}
