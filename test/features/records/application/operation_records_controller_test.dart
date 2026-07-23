import 'dart:async';

import 'package:flinx/features/records/application/providers.dart';
import 'package:flinx/features/records/domain/entities/operation_record.dart';
import 'package:flinx/features/records/domain/entities/operation_record_page_result.dart';
import 'package:flinx/features/records/domain/repositories/operation_record_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads the first page and appends the next page', () async {
    final repository = _RecordingRepository(<int, OperationRecordPageResult>{
      1: _result(<OperationRecord>[_record('First')], hasMore: true),
      2: _result(<OperationRecord>[_record('Second')], page: 2),
    });
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      operationRecordsControllerProvider.notifier,
    );

    await controller.loadInitial(doorId: '10001');
    await controller.loadMore();

    expect(
      container
          .read(operationRecordsControllerProvider)
          .records
          .map((record) => record.doorName),
      <String?>['First', 'Second'],
    );
    expect(repository.requestedPages, <int>[1, 2]);
  });

  test('refresh replaces loaded records with the first page', () async {
    final repository = _RecordingRepository(<int, OperationRecordPageResult>{
      1: _result(<OperationRecord>[_record('Before refresh')]),
    });
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      operationRecordsControllerProvider.notifier,
    );

    await controller.loadInitial(doorId: '10001');
    repository.pages[1] = _result(<OperationRecord>[_record('After refresh')]);
    await controller.refresh();

    expect(
      container
          .read(operationRecordsControllerProvider)
          .records
          .single
          .doorName,
      'After refresh',
    );
    expect(repository.requestedPages, <int>[1, 1]);
  });

  test('does not request more when the result has no more pages', () async {
    final repository = _RecordingRepository(<int, OperationRecordPageResult>{
      1: _result(<OperationRecord>[_record('Only')]),
    });
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      operationRecordsControllerProvider.notifier,
    );

    await controller.loadInitial(doorId: '10001');
    await controller.loadMore();

    expect(repository.requestedPages, <int>[1]);
  });

  test('ignores duplicate load-more requests while one is pending', () async {
    final nextPage = Completer<OperationRecordPageResult>();
    final repository = _RecordingRepository(<int, OperationRecordPageResult>{
      1: _result(<OperationRecord>[_record('First')], hasMore: true),
    }, pendingPage: nextPage);
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      operationRecordsControllerProvider.notifier,
    );

    await controller.loadInitial(doorId: '10001');
    final firstRequest = controller.loadMore();
    final duplicateRequest = controller.loadMore();

    expect(repository.requestedPages, <int>[1, 2]);
    nextPage.complete(_result(<OperationRecord>[_record('Second')], page: 2));
    await Future.wait<void>(<Future<void>>[firstRequest, duplicateRequest]);
  });
}

ProviderContainer _container(OperationRecordRepository repository) {
  return ProviderContainer(
    overrides: [
      operationRecordRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

OperationRecord _record(String doorName) => OperationRecord(
  action: OperationRecordAction.open,
  occurredAt: DateTime(2026, 7, 9, 13, 34, 52),
  doorName: doorName,
  operatorAccount: 'mark@f-linx.com',
);

OperationRecordPageResult _result(
  List<OperationRecord> records, {
  int page = 1,
  bool hasMore = false,
}) => OperationRecordPageResult(
  records: records,
  currentPage: page,
  pageSize: 20,
  total: hasMore ? 21 : records.length,
  hasMore: hasMore,
);

class _RecordingRepository implements OperationRecordRepository {
  _RecordingRepository(this.pages, {this.pendingPage});

  final Map<int, OperationRecordPageResult> pages;
  final Completer<OperationRecordPageResult>? pendingPage;
  final List<int> requestedPages = <int>[];

  @override
  Future<OperationRecordPageResult> fetchOperationRecords({
    required String doorId,
    required int page,
    required int pageSize,
    required String requestId,
  }) {
    requestedPages.add(page);
    if (page == 2 && pendingPage != null) return pendingPage!.future;
    return Future<OperationRecordPageResult>.value(pages[page]!);
  }
}
