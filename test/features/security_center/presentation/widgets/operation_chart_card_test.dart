import 'package:flinx/features/security_center/domain/entities/full_report.dart';
import 'package:flinx/features/security_center/presentation/widgets/security_report_widgets.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses one-step y-axis values when every operation bucket is zero', () {
    final points = List<FullReportOperationCyclePoint>.generate(
      24,
      (hour) => FullReportOperationCyclePoint(
        occurredAt: DateTime(1970, 1, 1, hour),
        axisLabel: hour.toString().padLeft(2, '0'),
        cycles: 0,
      ),
    );

    expect(operationChartYAxisLabels(points), [0, 1, 2, 3, 4, 5]);
  });

  test('uses one-step y-axis values when no operation data is available', () {
    expect(
      operationChartYAxisLabels(const <FullReportOperationCyclePoint>[]),
      [0, 1, 2, 3, 4, 5],
    );
  });

  test('shares the y-axis scale with sensor operation cycles', () {
    expect(
      operationChartYAxisLabelsForValues(const <int>[]),
      [0, 1, 2, 3, 4, 5],
    );
    expect(
      operationChartYAxisLabelsForValues(const <int>[17]),
      [0, 5, 10, 15, 20, 25],
    );
  });

  test('uses equal y-axis intervals when operation data is non-zero', () {
    final points = [
      FullReportOperationCyclePoint(
        occurredAt: DateTime(2026, 7, 22),
        cycles: 10,
      ),
    ];

    expect(operationChartYAxisLabels(points), [0, 3, 6, 9, 12, 15]);
  });

  test('adjusts the equal interval when the data maximum changes', () {
    final points = [
      FullReportOperationCyclePoint(
        occurredAt: DateTime(2026, 7, 22),
        cycles: 17,
      ),
    ];

    expect(operationChartYAxisLabels(points), [0, 5, 10, 15, 20, 25]);
  });

  testWidgets('uses the record abnormal status for both chart ranges', (
    tester,
  ) async {
    Future<void> pumpCard(RecordRange range) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: OperationChartCard(
            range: range,
            record: FullReportOperationRecord(
              hasFrequentOperationAlert: true,
              points: [
                FullReportOperationCyclePoint(
                  occurredAt: DateTime(2026, 7, 22),
                  axisLabel: '08',
                  cycles: 21,
                  isFrequentOperation: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await pumpCard(RecordRange.last24Hours);
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.textContaining('Unusually frequent operation'), findsOneWidget);

    await pumpCard(RecordRange.last7Days);
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.textContaining('Unusually frequent operation'), findsOneWidget);
  });

  testWidgets('shows a selected chart state only while a bar is touched', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: OperationChartCard(
              range: RecordRange.last7Days,
              record: FullReportOperationRecord(
                points: [
                  FullReportOperationCyclePoint(
                    occurredAt: DateTime(2026, 7, 22),
                    axisLabel: 'Wed',
                    cycles: 6,
                  ),
                  FullReportOperationCyclePoint(
                    occurredAt: DateTime(2026, 7, 23),
                    axisLabel: 'Thu',
                    cycles: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final chartFinder = find.byKey(
      const ValueKey<String>('operation-chart-selected-none'),
    );
    final chart = tester.getRect(chartFinder);
    final gesture = await tester.startGesture(
      Offset(chart.left + 22, chart.top + 50),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('operation-chart-selected-0')),
      findsOneWidget,
    );

    await gesture.moveTo(Offset(chart.left + 120, chart.top + 15));
    await tester.pump();
    expect(chartFinder, findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(chartFinder, findsOneWidget);
  });
}
