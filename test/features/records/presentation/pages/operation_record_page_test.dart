import 'package:flinx/features/records/application/providers.dart';
import 'package:flinx/features/records/domain/entities/operation_record.dart';
import 'package:flinx/features/records/domain/entities/operation_record_page_result.dart';
import 'package:flinx/features/records/domain/repositories/operation_record_repository.dart';
import 'package:flinx/features/records/presentation/pages/operation_record_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders records and the completed pagination footer', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      repository: _FakeOperationRecordRepository(
        pages: <int, OperationRecordPageResult>{
          1: _result(<OperationRecord>[
            _record('Open door'),
            _record('Close door'),
          ]),
        },
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Open door'), findsOneWidget);
    expect(find.text('2026-07-09 13:34:52'), findsNWidgets(2));
    expect(find.text('Garage door'), findsNWidgets(2));
    expect(find.text('mark@f-linx.com'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey<String>('operation-record-divider')),
      findsOneWidget,
    );
    expect(find.text('No more records'), findsOneWidget);
  });

  testWidgets('loads the next page when scrolling near the bottom', (
    tester,
  ) async {
    final firstPage = List<OperationRecord>.generate(
      20,
      (index) => _record('Record $index'),
    );
    await _pumpPage(
      tester,
      repository: _FakeOperationRecordRepository(
        pages: <int, OperationRecordPageResult>{
          1: _result(firstPage, hasMore: true),
          2: _result(<OperationRecord>[_record('Loaded next page')], page: 2),
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(find.text('Loaded next page'), findsOneWidget);
  });

  testWidgets('uses the named avatar placeholder when the URL is empty', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      repository: _FakeOperationRecordRepository(
        pages: <int, OperationRecordPageResult>{
          1: _result(<OperationRecord>[_record('Open door')]),
        },
      ),
    );
    await tester.pumpAndSettle();

    final avatar = tester.widget<CircleAvatar>(
      find.byKey(const ValueKey<String>('operation-record-avatar')),
    );
    expect(avatar.radius, 10);
    expect(
      (avatar.backgroundImage! as AssetImage).assetName,
      'assets/images/records/operation_record_avatar_placeholder.png',
    );
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required OperationRecordRepository repository,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        operationRecordRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OperationRecordPage(onTabSelected: (_) {}),
      ),
    ),
  );
}

OperationRecord _record(String operationName) => OperationRecord(
  operationName: operationName,
  operationTimeText: '2026-07-09 13:34:52',
  deviceName: 'Garage door',
  operatorEmail: 'mark@f-linx.com',
);

OperationRecordPageResult _result(
  List<OperationRecord> records, {
  int page = 1,
  bool hasMore = false,
}) => OperationRecordPageResult(
  records: records,
  currentPage: page,
  hasMore: hasMore,
);

class _FakeOperationRecordRepository implements OperationRecordRepository {
  _FakeOperationRecordRepository({required this.pages});

  final Map<int, OperationRecordPageResult> pages;

  @override
  Future<OperationRecordPageResult> fetchOperationRecords({
    required int page,
    required int pageSize,
  }) async => pages[page]!;
}
