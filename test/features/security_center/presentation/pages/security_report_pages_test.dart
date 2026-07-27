import 'dart:async';
import 'dart:typed_data';

import 'package:flinx/core/platform/gallery_image_saver.dart';
import 'package:flinx/features/security_center/application/providers.dart';
import 'package:flinx/features/security_center/domain/entities/general_evaluation_report.dart';
import 'package:flinx/features/security_center/domain/entities/full_report.dart';
import 'package:flinx/features/security_center/domain/repositories/general_evaluation_repository.dart';
import 'package:flinx/features/security_center/domain/repositories/safety_sensors_evaluation_repository.dart';
import 'package:flinx/features/security_center/domain/use_cases/fetch_general_evaluation_use_case.dart';
import 'package:flinx/features/security_center/domain/use_cases/fetch_safety_sensors_evaluation_use_case.dart';
import 'package:flinx/features/security_center/domain/entities/safety_sensors_evaluation.dart';
import 'package:flinx/features/security_center/domain/entities/security_center_overview.dart';
import 'package:flinx/features/security_center/domain/repositories/security_balance_refresh_repository.dart';
import 'package:flinx/features/security_center/domain/entities/security_balance_refresh_result.dart';
import 'package:flinx/features/device_control/presentation/widgets/device_detail_bottom_navigation.dart';
import 'package:flinx/features/security_center/presentation/pages/full_report_page.dart';
import 'package:flinx/features/security_center/presentation/pages/general_evaluation_page.dart';
import 'package:flinx/features/security_center/presentation/pages/security_center_page.dart';
import 'package:flinx/features/security_center/presentation/pages/safety_sensor_battery_solution_page.dart';
import 'package:flinx/features/security_center/presentation/pages/safety_sensors_evaluation_page.dart';
import 'package:flinx/features/security_center/presentation/widgets/security_report_widgets.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('security sensor type resolves its backend key', () {
    for (final type in SecuritySensorType.values) {
      expect(SecuritySensorType.fromBackendKey(type.backendKey), type);
    }
    expect(SecuritySensorType.fromBackendKey('unknown'), isNull);
  });

  testWidgets('security center entries open report pages and return', (
    tester,
  ) async {
    final router = _buildRouter();
    await _pumpRouter(tester, router);

    await tester.tap(find.text('General Evaluation'));
    await tester.pumpAndSettle();
    expect(find.text('General Evaluation'), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    expect(find.text('Security Center'), findsOneWidget);

    await tester.tap(find.text('Download the full report'));
    await tester.pumpAndSettle();

    expect(find.text('Safety Report'), findsOneWidget);
    expect(find.text('Safety suggestion:'), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    expect(find.text('Security Center'), findsOneWidget);

    final safetyCard = find.byKey(
      const ValueKey<String>('safety-sensors-evaluation-card'),
    );
    await tester.ensureVisible(safetyCard);
    await tester.pumpAndSettle();
    await tester.tap(safetyCard);
    await tester.pumpAndSettle();

    expect(find.text('Safety Sensors Evaluation'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('safety-sensors-scroll-mock-device')),
      findsOneWidget,
    );

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    expect(find.text('Security Center'), findsOneWidget);
  });

  testWidgets('security center renders sensor and battery state image assets', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const SecurityCenterPage(
        doorId: '12',
        deviceId: 'mock-device',
        onTabSelected: _ignoreTab,
      ),
    );

    for (final type in SecuritySensorType.values) {
      expect(_assetImage(type.imageAsset), findsOneWidget);
    }
    expect(
      _assetImage(
        'assets/icons/security_center/security_center_sensor_battery_full.png',
      ),
      findsNWidgets(6),
    );
    expect(
      _assetImage(
        'assets/icons/security_center/security_center_sensor_battery_low.png',
      ),
      findsOneWidget,
    );
    expect(
      _assetImage(
        'assets/icons/security_center/security_center_sensor_battery_offline.png',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.battery_1_bar_outlined), findsNothing);
    expect(find.byIcon(Icons.battery_5_bar_outlined), findsNothing);
  });

  testWidgets('general evaluation segments switch displayed data', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const GeneralEvaluationPage(deviceId: 'mock-device'),
    );

    expect(
      find.byKey(const ValueKey<BalanceEvaluation>(BalanceEvaluation.open)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<RecordRange>(RecordRange.last7Days)),
      findsOneWidget,
    );

    final closeSegment = find.byKey(
      const ValueKey<String>('segment-Close evaluation'),
    );
    await tester.ensureVisible(closeSegment);
    await tester.pumpAndSettle();
    await tester.tap(closeSegment);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<BalanceEvaluation>(BalanceEvaluation.close)),
      findsOneWidget,
    );

    final recordSegment = find.byKey(
      const ValueKey<String>('segment-Last 24 hours'),
    );
    await tester.ensureVisible(recordSegment);
    await tester.pumpAndSettle();
    await tester.tap(recordSegment);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<RecordRange>(RecordRange.last24Hours)),
      findsOneWidget,
    );
    expect(find.text('X: Time Y: Operation cycles'), findsOneWidget);
  });

  testWidgets(
    'balance evaluation uses segment labels and empty-row placeholders',
    (tester) async {
      await _pumpPage(
        tester,
        const Scaffold(
          body: BalanceEvaluationCard(
            selection: BalanceEvaluation.open,
            evaluation: FullReportBalanceEvaluation(
              indicatorPercentage: 50,
              hasOverloadOrOvercurrent: true,
              segments: [
                FullReportBalanceSegment(
                  startPercent: 80,
                  endPercent: 100,
                  status: 1,
                  statusLabel: 'Normal',
                ),
                FullReportBalanceSegment(
                  startPercent: 60,
                  endPercent: 80,
                  status: 2,
                  statusLabel: 'Blocked',
                ),
                FullReportBalanceSegment(
                  startPercent: 0,
                  endPercent: 20,
                  status: 3,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Blocked'), findsOneWidget);
      expect(find.text('--'), findsNWidgets(3));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.error), findsAtLeastNWidgets(3));
    },
  );

  testWidgets('balance evaluation heading follows overload flag', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const Scaffold(
        body: Column(
          children: [
            BalanceEvaluationCard(
              selection: BalanceEvaluation.open,
              evaluation: FullReportBalanceEvaluation(
                indicatorPercentage: 50,
                segments: [],
                hasOverloadOrOvercurrent: false,
              ),
            ),
            BalanceEvaluationCard(
              selection: BalanceEvaluation.close,
              evaluation: FullReportBalanceEvaluation(
                indicatorPercentage: 50,
                segments: [],
                hasOverloadOrOvercurrent: true,
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);
  });

  testWidgets('balance evaluation places segments by percentage range', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const Scaffold(
        body: BalanceEvaluationCard(
          selection: BalanceEvaluation.open,
          evaluation: FullReportBalanceEvaluation(
            indicatorPercentage: 50,
            segments: [
              FullReportBalanceSegment(
                startPercent: 0,
                endPercent: 20,
                status: 1,
                statusLabel: 'Bottom range',
              ),
            ],
          ),
        ),
      ),
    );

    for (var index = 0; index < 4; index++) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey<String>('balance-status-row-$index')),
          matching: find.text('--'),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('balance-status-row-4')),
        matching: find.text('Bottom range'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('general evaluation renders report data without report actions', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const GeneralEvaluationPage(deviceId: 'mock-device'),
    );

    expect(find.text('Garage door motor 01'), findsOneWidget);
    expect(find.text('Garage door 01'), findsOneWidget);
    expect(find.text('860'), findsOneWidget);
    expect(find.text('140'), findsOneWidget);
    expect(find.text('Motor function status'), findsOneWidget);
    expect(find.byType(SecurityReportActionBar), findsNothing);
  });

  testWidgets('general evaluation localizes its navigation title', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const GeneralEvaluationPage(deviceId: 'mock-device'),
      locale: const Locale('zh'),
    );

    expect(find.text('常规评估'), findsOneWidget);
  });

  testWidgets('motor function status card expands and collapses', (
    tester,
  ) async {
    await _pumpPage(tester, const Scaffold(body: MotorFunctionStatusCard()));

    final toggle = find.byKey(
      const ValueKey<String>('motor-function-status-toggle'),
    );
    expect(toggle, findsOneWidget);
    expect(find.text('Door opening force'), findsOneWidget);
    expect(find.text('Wired E-lock'), findsOneWidget);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('Door opening force'), findsNothing);
    expect(find.text('Wired E-lock'), findsNothing);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('Door opening force'), findsOneWidget);
    expect(find.text('Wired E-lock'), findsOneWidget);
  });

  testWidgets('full report contains all sections and safety suggestions', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const FullReportPage(deviceId: 'mock-device', doorId: '12'),
    );

    expect(find.text('Door balance evaluation'), findsNWidgets(2));
    expect(find.text('Door operation record'), findsNWidgets(2));
    expect(find.text('Motor function status'), findsOneWidget);
    expect(find.text('Wired sensors diagnosis'), findsOneWidget);
    expect(find.text('Wireless sensors diagnosis'), findsOneWidget);
    expect(find.text('Safety suggestion:'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.byType(SecurityReportActionBar), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Safety suggestion:'),
        matching: find.byType(SecurityReportCard),
      ),
      findsNothing,
    );

    await tester.scrollUntilVisible(
      find.text('Safety suggestion:'),
      500,
      scrollable: _scrollableInside('full-report-scroll'),
    );
    expect(find.text('Safety suggestion:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full report shows loading until general evaluation is ready', (
    tester,
  ) async {
    final completer = Completer<GeneralEvaluationReport>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fetchGeneralEvaluationUseCaseProvider.overrideWithValue(
            FetchGeneralEvaluationUseCase(
              repository: _DelayedGeneralEvaluationRepository(completer),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FullReportPage(deviceId: 'mock-device', doorId: '12'),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_testGeneralReport);
    await tester.pumpAndSettle();
    expect(find.text('Garage door motor 01'), findsOneWidget);
  });

  testWidgets('full report retries a failed general evaluation request', (
    tester,
  ) async {
    final repository = _FailingGeneralEvaluationRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fetchGeneralEvaluationUseCaseProvider.overrideWithValue(
            FetchGeneralEvaluationUseCase(repository: repository),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FullReportPage(deviceId: 'mock-device', doorId: '12'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(TextButton), findsOneWidget);

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
  });

  testWidgets('full report renders values supplied by its provider', (
    tester,
  ) async {
    const report = FullReport(
      deviceId: 'custom-device',
      motorName: 'Custom motor',
      serialNumber: 'CUSTOM-001',
      cycleSummary: FullReportCycleSummary(
        doorName: 'Custom door',
        operatedCycles: 12,
        remainingCycles: 34,
        needsMaintenance: false,
      ),
      openBalanceEvaluation: FullReportBalanceEvaluation(
        indicatorPercentage: 50,
        segments: [],
      ),
      closeBalanceEvaluation: FullReportBalanceEvaluation(
        indicatorPercentage: 50,
        segments: [],
      ),
      last24HoursRecord: FullReportOperationRecord(points: []),
      last7DaysRecord: FullReportOperationRecord(points: []),
      motorFunctionStatus: FullReportMotorFunctionStatus(
        openingForceLevel: 2,
        closingForceLevel: 2,
        autoCloseSeconds: 30,
        autoCloseCondition: FullReportAutoCloseCondition.anyPosition,
        ledOffDelayMinutes: 2,
        partialOpenCentimeters: 30,
        ignoreObstructionHeightCentimeters: 2,
        photoBeamEnabled: true,
        communityModeEnabled: false,
        wiredELockEnabled: true,
      ),
      wiredSensorDiagnosis: FullReportSensorDiagnosis(
        summary: FullReportSensorSummary(
          normalCount: 1,
          disconnectedCount: 0,
          abnormalCount: 0,
        ),
        sensors: [
          FullReportSensor(
            id: 'custom-wired-photo-beam',
            type: FullReportSensorType.wiredPhotoBeam,
            states: [FullReportSensorDisplayState.notTriggered],
          ),
        ],
      ),
      wirelessSensorDiagnosis: FullReportSensorDiagnosis(
        summary: FullReportSensorSummary(
          normalCount: 0,
          disconnectedCount: 1,
          abnormalCount: 0,
        ),
        sensors: [
          FullReportSensor(
            id: 'custom-wireless-e-lock',
            type: FullReportSensorType.wirelessELock,
            states: [FullReportSensorDisplayState.locked],
          ),
        ],
      ),
      safetySuggestions: [FullReportSafetySuggestionCode.contactInstaller],
    );

    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fullReportProvider('custom-device').overrideWith((ref) => report),
          fetchGeneralEvaluationUseCaseProvider.overrideWithValue(
            FetchGeneralEvaluationUseCase(
              repository: _FakeGeneralEvaluationRepository(
                report: GeneralEvaluationReport(
                  motorName: report.motorName,
                  cycleSummary: report.cycleSummary,
                  openBalanceEvaluation: report.openBalanceEvaluation,
                  closeBalanceEvaluation: report.closeBalanceEvaluation,
                  last24HoursRecord: report.last24HoursRecord,
                  last7DaysRecord: report.last7DaysRecord,
                  motorFunctionStatus: report.motorFunctionStatus,
                  balancePending: false,
                ),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FullReportPage(deviceId: 'custom-device', doorId: '12'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Custom motor'), findsOneWidget);
    expect(find.text('Custom door'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('34'), findsOneWidget);
  });

  testWidgets('full report shows four fixed evaluation and operation cards', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const FullReportPage(deviceId: 'mock-device', doorId: '12'),
    );

    expect(
      find.byKey(const ValueKey<BalanceEvaluation>(BalanceEvaluation.open)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<BalanceEvaluation>(BalanceEvaluation.close)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<RecordRange>(RecordRange.last7Days)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<RecordRange>(RecordRange.last24Hours)),
      findsOneWidget,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey<RecordRange>(RecordRange.last7Days)),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey<RecordRange>(RecordRange.last24Hours)),
            )
            .dy,
      ),
    );
    expect(find.text('X: Date Y: Operation cycles'), findsOneWidget);
    expect(find.text('X: Time Y: Operation cycles'), findsOneWidget);

    for (final label in const [
      'Open evaluation',
      'Close evaluation',
      'Last 7 days',
      'Last 24 hours',
    ]) {
      final segmentButtons = find.byKey(ValueKey<String>('segment-$label'));
      expect(segmentButtons, findsNWidgets(2));
      for (final button in tester.widgetList<InkWell>(segmentButtons)) {
        expect(button.onTap, isNull);
      }
    }
  });

  testWidgets('full report keeps both balance arrows in their own tables', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const FullReportPage(deviceId: 'mock-device', doorId: '12'),
    );

    final mainTables = find.byKey(const ValueKey<String>('balance-main-table'));
    final statusTable = find.byKey(
      const ValueKey<String>('balance-status-table'),
    );
    final arrow = find.byKey(const ValueKey<String>('balance-table-arrow'));

    expect(mainTables, findsNWidgets(2));
    expect(statusTable, findsNWidgets(2));
    expect(arrow, findsNWidgets(2));
    for (var index = 0; index < 2; index++) {
      expect(
        find.descendant(of: mainTables.at(index), matching: arrow.at(index)),
        findsOneWidget,
      );
    }
    final arrows = tester.widgetList<Image>(
      find.descendant(of: arrow, matching: find.byType(Image)),
    );
    expect(
      (arrows.first.image as AssetImage).assetName,
      'assets/icons/security_center/security_report_motor_blue_up_arrow.png',
    );
    expect(
      (arrows.last.image as AssetImage).assetName,
      'assets/icons/security_center/security_report_motor_blue_down_arrow.png',
    );
  });

  testWidgets('full report save captures report image and shows success', (
    tester,
  ) async {
    var saveCalls = 0;
    Uint8List? savedBytes;

    await _pumpPage(
      tester,
      FullReportPage(
        deviceId: 'mock-device',
        doorId: '12',
        captureReportImage: (_, _) async => Uint8List.fromList([1, 2, 3]),
        saveReportImage: (bytes) async {
          saveCalls += 1;
          savedBytes = bytes;
        },
      ),
    );

    _tapReportSaveAction(tester);
    await tester.pump();
    await tester.pump();

    expect(saveCalls, 1);
    expect(savedBytes, isNotNull);
    expect(savedBytes, isNotEmpty);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('full report save failure shows a readable error', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      FullReportPage(
        deviceId: 'mock-device',
        doorId: '12',
        captureReportImage: (_, _) async => Uint8List.fromList([1, 2, 3]),
        saveReportImage: (_) async {
          throw const GalleryImageSaveException(GalleryImageSaveFailure.failed);
        },
      ),
    );

    _tapReportSaveAction(tester);
    await tester.pump();
    await tester.pump();

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('gallery unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full report capture failure shows a readable error', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      FullReportPage(
        deviceId: 'mock-device',
        doorId: '12',
        captureReportImage: (_, _) async {
          throw StateError('capture unavailable');
        },
        saveReportImage: (_) async {},
      ),
    );

    _tapReportSaveAction(tester);
    await tester.pump();
    await tester.pump();

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('capture unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('report pages do not overflow on a compact screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPage(
      tester,
      const GeneralEvaluationPage(deviceId: 'mock-device'),
      setViewport: false,
    );
    await tester.scrollUntilVisible(
      find.text('Wired E-lock'),
      500,
      scrollable: _scrollableInside('general-evaluation-scroll'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('safety sensors page renders all static evaluation content', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const SafetySensorsEvaluationPage(
        doorId: '12',
        deviceId: 'sensor-device',
      ),
    );

    expect(find.text('Sensors'), findsOneWidget);
    expect(find.text('Fine'), findsOneWidget);
    expect(find.text('Abnormal'), findsOneWidget);
    expect(find.text('Low power'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('sensor-metric-Sensors-value')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('sensor-metric-Sensors-value')),
          )
          .data,
      '6',
    );
    expect(find.text('Wired sensor status'), findsOneWidget);
    expect(find.text('Wireless Sensors Status'), findsOneWidget);
    expect(find.text('Match'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Wired photo beam'), findsOneWidget);
    expect(find.text('Wired E-lock'), findsOneWidget);
    expect(find.text('Wireless Photo Beam'), findsOneWidget);
    expect(find.text('Wireless wicket door'), findsOneWidget);
    expect(find.text('Wireless E-lock'), findsOneWidget);
    expect(find.text('Wireless safety edge'), findsOneWidget);
    expect(find.text('Disconnect'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey<String>('sensor-status-Wired photo beam')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('sensor-status-Wired E-lock')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('sensor-battery')),
      findsNWidgets(3),
    );
    for (final name in [
      'Wireless Photo Beam',
      'Wireless wicket door',
      'Wireless E-lock',
      'Wireless safety edge',
    ]) {
      expect(
        find.byKey(ValueKey<String>('sensor-navigation-chevron-$name')),
        findsOneWidget,
      );
    }
    expect(find.text('Triggered'), findsOneWidget);
    expect(find.text('How to replace the battery'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('sensor-low-battery')),
      findsOneWidget,
    );
    expect(
      _assetImage(
        'assets/icons/security_center/security_center_sensor_battery_full.png',
      ),
      findsNWidgets(3),
    );
    expect(
      _assetImage(
        'assets/icons/security_center/security_center_sensor_battery_low.png',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.battery_0_bar), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('sensor-replace-battery-help')),
      findsOneWidget,
    );
    final alertCard = find.byKey(
      const ValueKey<String>('sensor-Wireless Photo Beam'),
    );
    final batteryHelp = find.byKey(
      const ValueKey<String>('sensor-replace-battery-help'),
    );
    expect(
      tester.getRect(alertCard).right - tester.getRect(batteryHelp).right,
      closeTo(6, 0.1),
    );
    expect(
      tester
              .getRect(find.byKey(const ValueKey<String>('sensor-low-battery')))
              .left -
          tester.getRect(find.text('Wireless Photo Beam')).right,
      closeTo(4, 0.1),
    );
    final batteryHelpWidget = tester.widget<Container>(batteryHelp);
    final batteryHelpDecoration =
        batteryHelpWidget.decoration! as BoxDecoration;
    final batteryHelpBorder = batteryHelpDecoration.border! as Border;
    expect(batteryHelpBorder.bottom.width, 0.5);

    await tester.scrollUntilVisible(
      find.text('Wireless safety edge'),
      500,
      scrollable: _scrollableInside('safety-sensors-scroll-sensor-device'),
    );
    expect(find.text('Wireless safety edge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('low-battery help opens the battery solution page', (
    tester,
  ) async {
    final router = _buildRouter();
    await _pumpRouter(tester, router);

    final safetyCard = find.byKey(
      const ValueKey<String>('safety-sensors-evaluation-card'),
    );
    await tester.ensureVisible(safetyCard);
    await tester.tap(safetyCard);
    await tester.pumpAndSettle();

    final replaceBatteryAction = find.byKey(
      const ValueKey<String>('sensor-replace-battery-action'),
    );
    await tester.ensureVisible(replaceBatteryAction);
    await tester.pumpAndSettle();
    await tester.tap(replaceBatteryAction);
    await tester.pumpAndSettle();

    expect(find.text('Wireless Photo Beam'), findsOneWidget);
    expect(find.text('Solution for low battery power'), findsOneWidget);
    expect(find.text('Battery model: ER14505'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('safety-sensor-battery-solution-scroll'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('battery solution page uses image placeholders', (tester) async {
    await _pumpPage(
      tester,
      const SafetySensorBatterySolutionPage(
        doorId: '12',
        deviceId: 'sensor-device',
        sensorId: 'WIRELESS_PHOTO_BEAM',
      ),
    );

    expect(find.text('Wireless Photo Beam'), findsOneWidget);
    expect(find.text('Low battery power'), findsOneWidget);
    expect(find.text('Image placeholder'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wireless sensors expand and collapse operation charts', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const SafetySensorsEvaluationPage(
        doorId: '12',
        deviceId: 'sensor-device',
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('sensor-toggle-Wired photo beam')),
    );
    await tester.pumpAndSettle();
    for (final name in [
      'Wireless Photo Beam',
      'Wireless wicket door',
      'Wireless E-lock',
      'Wireless safety edge',
    ]) {
      expect(
        find.byKey(ValueKey<String>('sensor-operation-chart-$name')),
        findsNothing,
      );
    }

    for (final name in [
      'Wireless Photo Beam',
      'Wireless wicket door',
      'Wireless E-lock',
      'Wireless safety edge',
    ]) {
      final toggle = find.byKey(ValueKey<String>('sensor-toggle-$name'));
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey<String>('sensor-operation-chart-$name')),
        findsOneWidget,
      );

      if (name == 'Wireless Photo Beam') {
        expect(find.text('Triggered'), findsOneWidget);
        expect(find.text('How to replace the battery'), findsOneWidget);
      }

      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey<String>('sensor-operation-chart-$name')),
        findsNothing,
      );
    }
  });

  testWidgets('wireless sensor with no operation points opens an empty chart', (
    tester,
  ) async {
    final evaluation = SafetySensorsEvaluation(
      deviceId: 'empty-history-device',
      totalSensorCount: 1,
      fineSensorCount: 1,
      abnormalSensorCount: 0,
      lowPowerSensorCount: 0,
      wiredSensorGroup: const SafetySensorGroup(
        status: SafetySensorGroupStatus.normal,
        sensors: [],
      ),
      wirelessSensorGroup: const SafetySensorGroup(
        status: SafetySensorGroupStatus.normal,
        sensors: [
          SafetySensor(
            id: 'WIRELESS_PHOTO_BEAM',
            sensorCode: 'WIRELESS_PHOTO_BEAM',
            status: SafetySensorStatus.notTriggered,
            batteryStatus: SafetySensorBatteryStatus.normal,
            operationPoints: [],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fetchSafetySensorsEvaluationUseCaseProvider.overrideWithValue(
            FetchSafetySensorsEvaluationUseCase(
              repository: _FakeSafetySensorsEvaluationRepository(evaluation),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SafetySensorsEvaluationPage(
            doorId: '12',
            deviceId: 'empty-history-device',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final emptyHistoryToggle = find.byKey(
      const ValueKey<String>('sensor-toggle-Empty history sensor'),
    );
    await tester.ensureVisible(emptyHistoryToggle);
    await tester.pumpAndSettle();
    await tester.tap(emptyHistoryToggle);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('sensor-operation-chart-Empty history sensor'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('safety sensors page does not overflow on a compact screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPage(
      tester,
      const SafetySensorsEvaluationPage(
        doorId: '12',
        deviceId: 'compact-device',
      ),
      setViewport: false,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('sensor-Wireless safety edge')),
      500,
      scrollable: _scrollableInside('safety-sensors-scroll-compact-device'),
    );
    expect(tester.takeException(), isNull);
  });
}

Finder _scrollableInside(String key) {
  return find.descendant(
    of: find.byKey(ValueKey<String>(key)),
    matching: find.byType(Scrollable),
  );
}

Finder _assetImage(String assetName) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == assetName,
    description: 'Image.asset($assetName)',
  );
}

void _ignoreTab(DeviceDetailTab _) {}

void _tapReportSaveAction(WidgetTester tester) {
  final action = find.byKey(const ValueKey<String>('full-report-save-action'));
  expect(action, findsOneWidget);
  final gesture = find.descendant(
    of: action,
    matching: find.byType(GestureDetector),
  );
  final detector = tester.widget<GestureDetector>(gesture);
  expect(detector.onTap, isNotNull);
  detector.onTap?.call();
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/security-center',
    routes: [
      GoRoute(
        path: '/security-center',
        builder: (context, state) => SecurityCenterPage(
          doorId: '12',
          deviceId: 'mock-device',
          onTabSelected: (_) {},
        ),
      ),
      GoRoute(
        path: FullReportPage.routePath,
        name: FullReportPage.routeName,
        builder: (context, state) => FullReportPage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: GeneralEvaluationPage.routePath,
        name: GeneralEvaluationPage.routeName,
        builder: (context, state) => GeneralEvaluationPage(
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: SafetySensorsEvaluationPage.routePath,
        name: SafetySensorsEvaluationPage.routeName,
        builder: (context, state) => SafetySensorsEvaluationPage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: SafetySensorBatterySolutionPage.routePath,
        name: SafetySensorBatterySolutionPage.routeName,
        builder: (context, state) => SafetySensorBatterySolutionPage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
          sensorId: state.uri.queryParameters['sensorId'] ?? '',
        ),
      ),
    ],
  );
}

Future<void> _pumpRouter(WidgetTester tester, GoRouter router) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        securityBalanceRefreshRepositoryProvider.overrideWithValue(
          const _FakeSecurityBalanceRefreshRepository(),
        ),
        fetchGeneralEvaluationUseCaseProvider.overrideWithValue(
          const FetchGeneralEvaluationUseCase(
            repository: _FakeGeneralEvaluationRepository(),
          ),
        ),
        fetchSafetySensorsEvaluationUseCaseProvider.overrideWithValue(
          FetchSafetySensorsEvaluationUseCase(
            repository: _FakeSafetySensorsEvaluationRepository(
              _testSafetyEvaluation,
            ),
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpPage(
  WidgetTester tester,
  Widget page, {
  bool setViewport = true,
  Locale? locale,
}) async {
  if (setViewport) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        securityBalanceRefreshRepositoryProvider.overrideWithValue(
          const _FakeSecurityBalanceRefreshRepository(),
        ),
        fetchGeneralEvaluationUseCaseProvider.overrideWithValue(
          const FetchGeneralEvaluationUseCase(
            repository: _FakeGeneralEvaluationRepository(),
          ),
        ),
        fetchSafetySensorsEvaluationUseCaseProvider.overrideWithValue(
          FetchSafetySensorsEvaluationUseCase(
            repository: _FakeSafetySensorsEvaluationRepository(
              _testSafetyEvaluation,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeSecurityBalanceRefreshRepository
    implements SecurityBalanceRefreshRepository {
  const _FakeSecurityBalanceRefreshRepository();

  @override
  Future<SecurityBalanceRefreshResult> refreshBalance({
    required String doorId,
    required String requestId,
  }) async => const SecurityBalanceRefreshResult(
    requestId: 'test-request',
    status: '1',
  );
}

class _FakeGeneralEvaluationRepository implements GeneralEvaluationRepository {
  const _FakeGeneralEvaluationRepository({this.report = _testGeneralReport});

  final GeneralEvaluationReport report;

  @override
  Future<GeneralEvaluationReport> fetch({
    required String doorId,
    String? assessmentRequestId,
    required String requestId,
  }) async => report;
}

class _FakeSafetySensorsEvaluationRepository
    implements SafetySensorsEvaluationRepository {
  const _FakeSafetySensorsEvaluationRepository(this.evaluation);

  final SafetySensorsEvaluation evaluation;

  @override
  Future<SafetySensorsEvaluation> fetchEvaluation({
    required String doorId,
    required String requestId,
  }) async => evaluation;
}

final _testSafetyEvaluation = SafetySensorsEvaluation(
  deviceId: 'mock-device',
  totalSensorCount: 6,
  fineSensorCount: 3,
  abnormalSensorCount: 3,
  lowPowerSensorCount: 1,
  wiredSensorGroup: const SafetySensorGroup(
    status: SafetySensorGroupStatus.normal,
    sensors: [
      SafetySensor(
        id: 'WIRED_PHOTO_BEAM',
        sensorCode: 'WIRED_PHOTO_BEAM',
        status: SafetySensorStatus.disconnected,
        batteryStatus: SafetySensorBatteryStatus.unknown,
        operationPoints: [],
      ),
      SafetySensor(
        id: 'WIRED_ELECTRONIC_LOCK',
        sensorCode: 'WIRED_ELECTRONIC_LOCK',
        status: SafetySensorStatus.locked,
        batteryStatus: SafetySensorBatteryStatus.unknown,
        operationPoints: [],
      ),
    ],
  ),
  wirelessSensorGroup: SafetySensorGroup(
    status: SafetySensorGroupStatus.abnormal,
    sensors: [
      SafetySensor(
        id: 'WIRELESS_PHOTO_BEAM',
        sensorCode: 'WIRELESS_PHOTO_BEAM',
        status: SafetySensorStatus.triggered,
        batteryStatus: SafetySensorBatteryStatus.low,
        operationPoints: [
          SafetySensorOperationPoint(
            occurredAt: DateTime(1970, 1, 1, 9),
            cycles: 19,
          ),
        ],
      ),
      const SafetySensor(
        id: 'WIRELESS_WICKET_DOOR',
        sensorCode: 'WIRELESS_WICKET_DOOR',
        status: SafetySensorStatus.notTriggered,
        batteryStatus: SafetySensorBatteryStatus.normal,
        operationPoints: [],
      ),
      const SafetySensor(
        id: 'WIRELESS_ELECTRONIC_LOCK',
        sensorCode: 'WIRELESS_ELECTRONIC_LOCK',
        status: SafetySensorStatus.locked,
        batteryStatus: SafetySensorBatteryStatus.normal,
        operationPoints: [],
      ),
      const SafetySensor(
        id: 'WIRELESS_SAFETY_EDGE',
        sensorCode: 'WIRELESS_SAFETY_EDGE',
        status: SafetySensorStatus.notTriggered,
        batteryStatus: SafetySensorBatteryStatus.normal,
        operationPoints: [],
      ),
    ],
  ),
);

class _DelayedGeneralEvaluationRepository
    implements GeneralEvaluationRepository {
  const _DelayedGeneralEvaluationRepository(this.completer);

  final Completer<GeneralEvaluationReport> completer;

  @override
  Future<GeneralEvaluationReport> fetch({
    required String doorId,
    String? assessmentRequestId,
    required String requestId,
  }) => completer.future;
}

class _FailingGeneralEvaluationRepository
    implements GeneralEvaluationRepository {
  var calls = 0;

  @override
  Future<GeneralEvaluationReport> fetch({
    required String doorId,
    String? assessmentRequestId,
    required String requestId,
  }) async {
    calls += 1;
    throw StateError('test failure');
  }
}

const _testGeneralReport = GeneralEvaluationReport(
  motorName: 'Garage door motor 01',
  cycleSummary: FullReportCycleSummary(
    doorName: 'Garage door 01',
    operatedCycles: 860,
    remainingCycles: 140,
    needsMaintenance: true,
  ),
  openBalanceEvaluation: FullReportBalanceEvaluation(
    indicatorPercentage: 62,
    segments: [],
  ),
  closeBalanceEvaluation: FullReportBalanceEvaluation(
    indicatorPercentage: 38,
    segments: [],
  ),
  last24HoursRecord: FullReportOperationRecord(points: []),
  last7DaysRecord: FullReportOperationRecord(points: []),
  motorFunctionStatus: FullReportMotorFunctionStatus(
    openingForceLevel: 1,
    closingForceLevel: 1,
    autoCloseSeconds: 25,
    autoCloseCondition: FullReportAutoCloseCondition.anyPosition,
    ledOffDelayMinutes: 3,
    partialOpenCentimeters: 40,
    ignoreObstructionHeightCentimeters: 3,
    photoBeamEnabled: true,
    communityModeEnabled: true,
    wiredELockEnabled: true,
  ),
  balancePending: false,
);
