import '../../domain/entities/operation_record.dart';
import '../../domain/entities/operation_record_page_result.dart';
import '../../domain/repositories/operation_record_repository.dart';

/// 当前用于页面联调的本地分页数据源；后续由远程仓库实现替换。
class MockOperationRecordRepository implements OperationRecordRepository {
  MockOperationRecordRepository({List<OperationRecord>? records})
    : _records = records ?? _demoRecords;

  final List<OperationRecord> _records;

  static final List<OperationRecord>
  _demoRecords = List<OperationRecord>.generate(
    40,
    (index) => OperationRecord(
      operationName: index.isEven ? 'Open door' : 'LED close',
      operationTimeText:
          '2026-07-${(9 - index ~/ 6).clamp(1, 9).toString().padLeft(2, '0')} ${((23 - index) % 24).toString().padLeft(2, '0')}:${(59 - index).abs().remainder(60).toString().padLeft(2, '0')}:00',
      deviceName: 'TestFoor',
      operatorEmail: '346054814@qq.com',
    ),
    growable: false,
  );

  @override
  Future<OperationRecordPageResult> fetchOperationRecords({
    required int page,
    required int pageSize,
  }) async {
    final start = (page - 1) * pageSize;
    if (start >= _records.length) {
      return OperationRecordPageResult(
        records: const <OperationRecord>[],
        currentPage: page,
        hasMore: false,
      );
    }
    final end = (start + pageSize).clamp(0, _records.length);
    return OperationRecordPageResult(
      records: _records.sublist(start, end),
      currentPage: page,
      hasMore: end < _records.length,
    );
  }
}
