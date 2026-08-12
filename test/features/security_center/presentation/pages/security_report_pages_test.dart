import 'dart:async';
import 'dart:typed_data';

import 'package:flinx/app/theme/app_design_tokens.dart';
import 'package:flinx/core/platform/gallery_image_saver.dart';
import 'package:flinx/features/security_center/application/providers.dart';
import 'package:flinx/features/security_center/application/safety_sensor_management_providers.dart';
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
import 'package:flinx/features/security_center/domain/entities/safety_sensor_pairing.dart';
import 'package:flinx/features/security_center/domain/repositories/safety_sensor_pairing_repository.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/features/device_control/presentation/widgets/device_detail_bottom_navigation.dart';
import 'package:flinx/features/security_center/presentation/pages/full_report_page.dart';
import 'package:flinx/features/security_center/presentation/pages/general_evaluation_page.dart';
import 'package:flinx/features/security_center/presentation/pages/security_center_page.dart';
import 'package:flinx/features/security_center/presentation/pages/safety_sensor_battery_solution_page.dart';
import 'package:flinx/features/security_center/presentation/pages/safety_sensor_management_page.dart';
import 'package:flinx/features/security_center/presentation/pages/safety_sensor_pairing_pages.dart';
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

  testWidgets('full report renders live sensor battery and status details', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const FullReportPage(deviceId: 'mock-device', doorId: '12'),
    );

    await tester.scrollUntilVisible(
      find.text('Battery is low'),
      500,
      scrollable: _scrollableInside('full-report-scroll'),
    );
    expect(find.text('Battery is low'), findsOneWidget);
    expect(find.text('Triggered'), findsOneWidget);
    expect(find.text('Offline'), findsAtLeastNWidgets(2));
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
          fetchSafetySensorsEvaluationUseCaseProvider.overrideWithValue(
            FetchSafetySensorsEvaluationUseCase(
              repository: _FakeSafetySensorsEvaluationRepository(
                _testSafetyEvaluation,
              ),
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
          fetchSafetySensorsEvaluationUseCaseProvider.overrideWithValue(
            FetchSafetySensorsEvaluationUseCase(
              repository: _FakeSafetySensorsEvaluationRepository(
                _testSafetyEvaluation,
              ),
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

    await tester.pumpAndSettle();
    expect(find.byType(TextButton), findsOneWidget);

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
  });

  testWidgets('full report renders values supplied by general evaluation', (
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
          fetchSafetySensorsEvaluationUseCaseProvider.overrideWithValue(
            FetchSafetySensorsEvaluationUseCase(
              repository: _FakeSafetySensorsEvaluationRepository(
                _testSafetyEvaluation,
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
    expect(
      find.byKey(const ValueKey<String>('sensor-door-layout-wired')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('sensor-door-layout-wireless')),
      findsOneWidget,
    );
    _expectMarker(tester, 'wired', 'WIRED_PHOTO_BEAM', 0, findsOneWidget);
    _expectMarker(tester, 'wired', 'WIRED_ELECTRONIC_LOCK', 1, findsOneWidget);
    _expectMarker(tester, 'wireless', 'WIRELESS_SLACK_ROPE', 2, findsOneWidget);
    _expectMarker(tester, 'wireless', 'WIRELESS_PHOTO_BEAM', 0, findsOneWidget);
    _expectMarker(tester, 'wireless', 'WIRELESS_PHOTO_BEAM', 5, findsOneWidget);
    _expectMarkerColor(
      tester,
      'wired',
      'WIRED_PHOTO_BEAM',
      0,
      AppColors.safetySensorDisconnected,
    );
    _expectMarkerColor(
      tester,
      'wired',
      'WIRED_ELECTRONIC_LOCK',
      1,
      AppColors.securityCenterError,
    );
    _expectMarkerColor(
      tester,
      'wireless',
      'WIRELESS_SLACK_ROPE',
      2,
      AppColors.safetySensorDisconnected,
    );
    _expectMarkerColor(
      tester,
      'wireless',
      'WIRELESS_PHOTO_BEAM',
      0,
      AppColors.securityCenterError,
    );
    _expectMarkerColor(
      tester,
      'wireless',
      'WIRELESS_PHOTO_BEAM',
      5,
      AppColors.securityCenterError,
    );
    _expectMarkersWithinDoor(
      tester,
      keyPrefix: 'wired',
      markerKeys: const ['WIRED_PHOTO_BEAM-0', 'WIRED_ELECTRONIC_LOCK-1'],
    );
    _expectMarkersWithinDoor(
      tester,
      keyPrefix: 'wireless',
      markerKeys: const [
        'WIRELESS_PHOTO_BEAM-0',
        'WIRELESS_SAFETY_EDGE-1',
        'WIRELESS_SLACK_ROPE-2',
        'WIRELESS_WICKET_DOOR-3',
        'WIRELESS_ELECTRONIC_LOCK-4',
        'WIRELESS_PHOTO_BEAM-5',
      ],
    );
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

  testWidgets('sensor pairing succeeds then returns to evaluation', (
    tester,
  ) async {
    final evaluationRepository = _CountingSafetySensorsEvaluationRepository(
      _testSafetyEvaluation,
    );
    final router = _buildRouter();
    await _pumpRouter(
      tester,
      router,
      evaluationRepository: evaluationRepository,
    );

    final safetyCard = find.byKey(
      const ValueKey<String>('safety-sensors-evaluation-card'),
    );
    await tester.ensureVisible(safetyCard);
    await tester.tap(safetyCard);
    await tester.pumpAndSettle();

    final match = find.byKey(const ValueKey<String>('safety-sensors-match'));
    await tester.drag(
      _scrollableInside('safety-sensors-scroll-mock-device'),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    await tester.tap(match);
    await tester.pumpAndSettle();
    expect(find.text('Sensor match'), findsOneWidget);
    expect(find.text('Keep Bluetooth on'), findsOneWidget);
    expect(
      find.byKey(
        ValueKey<String>(
          'safety-sensor-pairing-asset-'
          '${SafetySensorPairingGuidePage.guideAsset}',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('safety-sensor-pairing-start')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Wireless safety sensor learning successful'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('safety-sensor-pairing-complete')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Safety Sensors Evaluation'), findsOneWidget);
    expect(evaluationRepository.fetchCount, greaterThan(1));
  });

  testWidgets(
    'sensor match and management require a connected Bluetooth device',
    (tester) async {
      final router = _buildRouter();
      await _pumpRouter(
        tester,
        router,
        pairingRepository: const _DisconnectedSafetySensorPairingRepository(),
      );

      final safetyCard = find.byKey(
        const ValueKey<String>('safety-sensors-evaluation-card'),
      );
      await tester.ensureVisible(safetyCard);
      await tester.tap(safetyCard);
      await tester.pumpAndSettle();
      await tester.drag(
        _scrollableInside('safety-sensors-scroll-mock-device'),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('safety-sensors-match')),
      );
      await tester.pumpAndSettle();
      expect(
        router.state.matchedLocation,
        SafetySensorsEvaluationPage.routePath,
      );
      expect(
        find.text('Connect the selected device via Bluetooth to use Match.'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('safety-sensors-manage')),
      );
      await tester.pumpAndSettle();
      expect(
        router.state.matchedLocation,
        SafetySensorsEvaluationPage.routePath,
      );
      expect(
        find.text('Connect the selected device via Bluetooth to use Manage.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('cancelling pairing returns to evaluation', (tester) async {
    final router = _buildRouter();
    final pairingRepository = _PendingSafetySensorPairingRepository();
    await _pumpRouter(tester, router, pairingRepository: pairingRepository);

    final safetyCard = find.byKey(
      const ValueKey<String>('safety-sensors-evaluation-card'),
    );
    await tester.ensureVisible(safetyCard);
    await tester.tap(safetyCard);
    await tester.pumpAndSettle();
    final match = find.byKey(const ValueKey<String>('safety-sensors-match'));
    await tester.drag(
      _scrollableInside('safety-sensors-scroll-mock-device'),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    await tester.tap(match);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('safety-sensor-pairing-start')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('safety-sensor-pairing-cancel')),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('Safety Sensors Evaluation'), findsOneWidget);
    expect(pairingRepository.actions, [
      SafetyAccessoryPairingAction.start,
      SafetyAccessoryPairingAction.cancel,
    ]);
    expect(
      find.text('Wireless safety sensor learning successful'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pairing failure shows the result state and complete action', (
    tester,
  ) async {
    final router = _buildRouter();
    await _pumpRouter(
      tester,
      router,
      pairingRepository: const _FakeSafetySensorPairingRepository(
        status: SafetyAccessoryPairingStatus.failure,
        reasonCode: 0x01020004,
      ),
    );

    final safetyCard = find.byKey(
      const ValueKey<String>('safety-sensors-evaluation-card'),
    );
    await tester.ensureVisible(safetyCard);
    await tester.tap(safetyCard);
    await tester.pumpAndSettle();
    await tester.drag(
      _scrollableInside('safety-sensors-scroll-mock-device'),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('safety-sensors-match')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('safety-sensor-pairing-start')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wireless safety sensor learning failed'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('safety-sensor-pairing-complete')),
      findsOneWidget,
    );
    expect(find.text('Complete'), findsOneWidget);
    expect(find.textContaining('Fault code:'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('pairing timeout shows the failure result state', (tester) async {
    final router = _buildRouter();
    await _pumpRouter(
      tester,
      router,
      pairingRepository: const _FakeSafetySensorPairingRepository(
        status: SafetyAccessoryPairingStatus.timeout,
        reasonCode: 0x00000030,
      ),
    );

    final safetyCard = find.byKey(
      const ValueKey<String>('safety-sensors-evaluation-card'),
    );
    await tester.ensureVisible(safetyCard);
    await tester.tap(safetyCard);
    await tester.pumpAndSettle();
    await tester.drag(
      _scrollableInside('safety-sensors-scroll-mock-device'),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('safety-sensors-match')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('safety-sensor-pairing-start')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wireless safety sensor learning failed'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('safety-sensor-pairing-complete')),
      findsOneWidget,
    );
    expect(find.text('Complete'), findsOneWidget);
    expect(find.textContaining('Fault code:'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('sensor management deletes a wireless sensor over BLE', (
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
    await tester.drag(
      _scrollableInside('safety-sensors-scroll-mock-device'),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();
    expect(find.text('Sensor management'), findsOneWidget);
    expect(find.text('Wireless wicket door'), findsOneWidget);
    expect(find.text('Wireless E-lock'), findsOneWidget);

    final deleteAction = find.byKey(
      const ValueKey<String>('safety-sensor-management-delete-02000071'),
    );
    await tester.ensureVisible(deleteAction);
    await tester.tap(deleteAction);
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('safety-sensor-management-delete-dialog'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('safety-sensor-management-delete-cancel'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Wireless wicket door'), findsOneWidget);

    await tester.tap(deleteAction);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('safety-sensor-management-delete-confirm'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Wireless wicket door'), findsNothing);
    expect(find.text('Wireless E-lock'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('sensor-door-layout-wireless')),
      500,
      scrollable: _scrollableInside('safety-sensors-scroll-compact-device'),
    );
    _expectMarkersWithinDoor(
      tester,
      keyPrefix: 'wireless',
      markerKeys: const [
        'WIRELESS_PHOTO_BEAM-0',
        'WIRELESS_SAFETY_EDGE-1',
        'WIRELESS_SLACK_ROPE-2',
        'WIRELESS_WICKET_DOOR-3',
        'WIRELESS_ELECTRONIC_LOCK-4',
        'WIRELESS_PHOTO_BEAM-5',
      ],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('safety sensor points remain visible for nonzero statuses', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const SafetySensorsEvaluationPage(
        doorId: '12',
        deviceId: 'active-sensor-device',
      ),
      evaluation: _activeMarkerSafetyEvaluation,
    );

    _expectMarkersWithinDoor(
      tester,
      keyPrefix: 'wired',
      markerKeys: const ['WIRED_PHOTO_BEAM-0', 'WIRED_ELECTRONIC_LOCK-1'],
    );
    _expectMarkersWithinDoor(
      tester,
      keyPrefix: 'wireless',
      markerKeys: const [
        'WIRELESS_PHOTO_BEAM-0',
        'WIRELESS_SAFETY_EDGE-1',
        'WIRELESS_SLACK_ROPE-2',
        'WIRELESS_WICKET_DOOR-3',
        'WIRELESS_ELECTRONIC_LOCK-4',
        'WIRELESS_PHOTO_BEAM-5',
      ],
    );
    for (final marker in const [
      ('wired', 'WIRED_PHOTO_BEAM', 0),
      ('wired', 'WIRED_ELECTRONIC_LOCK', 1),
      ('wireless', 'WIRELESS_PHOTO_BEAM', 0),
      ('wireless', 'WIRELESS_SAFETY_EDGE', 1),
      ('wireless', 'WIRELESS_SLACK_ROPE', 2),
      ('wireless', 'WIRELESS_WICKET_DOOR', 3),
      ('wireless', 'WIRELESS_ELECTRONIC_LOCK', 4),
      ('wireless', 'WIRELESS_PHOTO_BEAM', 5),
    ]) {
      _expectMarkerColor(
        tester,
        marker.$1,
        marker.$2,
        marker.$3,
        AppColors.safetySensorAction,
      );
    }
  });

  testWidgets('safety sensor points use grey and red status colors', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const SafetySensorsEvaluationPage(
        doorId: '12',
        deviceId: 'status-sensor-device',
      ),
    );

    _expectMarkerColor(
      tester,
      'wired',
      'WIRED_PHOTO_BEAM',
      0,
      AppColors.safetySensorDisconnected,
    );
    _expectMarkerColor(
      tester,
      'wired',
      'WIRED_ELECTRONIC_LOCK',
      1,
      AppColors.securityCenterError,
    );
    _expectMarkerColor(
      tester,
      'wireless',
      'WIRELESS_SLACK_ROPE',
      2,
      AppColors.safetySensorDisconnected,
    );
    _expectMarkerColor(
      tester,
      'wireless',
      'WIRELESS_PHOTO_BEAM',
      0,
      AppColors.securityCenterError,
    );
    _expectMarkerColor(
      tester,
      'wireless',
      'WIRELESS_PHOTO_BEAM',
      5,
      AppColors.securityCenterError,
    );
  });
}

void _expectMarker(
  WidgetTester tester,
  String keyPrefix,
  String sensorCode,
  int index,
  Matcher matcher,
) => expect(
  find.byKey(
    ValueKey<String>('sensor-position-marker-$keyPrefix-$sensorCode-$index'),
  ),
  matcher,
);

void _expectMarkerColor(
  WidgetTester tester,
  String keyPrefix,
  String sensorCode,
  int index,
  Color color,
) {
  final marker = tester.widget<Container>(
    find.descendant(
      of: find.byKey(
        ValueKey<String>(
          'sensor-position-marker-$keyPrefix-$sensorCode-$index',
        ),
      ),
      matching: find.byType(Container),
    ),
  );
  expect((marker.decoration! as BoxDecoration).color, color);
}

void _expectMarkersWithinDoor(
  WidgetTester tester, {
  required String keyPrefix,
  required List<String> markerKeys,
}) {
  final doorRect = tester.getRect(
    find.byKey(ValueKey<String>('sensor-door-layout-$keyPrefix')),
  );
  for (final markerKey in markerKeys) {
    final markerRect = tester.getRect(
      find.byKey(
        ValueKey<String>('sensor-position-marker-$keyPrefix-$markerKey'),
      ),
    );
    expect(doorRect.overlaps(markerRect), isTrue);
  }
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
      GoRoute(
        path: SafetySensorManagementPage.routePath,
        builder: (context, state) => SafetySensorManagementPage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: SafetySensorPairingGuidePage.routePath,
        builder: (context, state) => SafetySensorPairingGuidePage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: SafetySensorPairingMatchingPage.routePath,
        builder: (context, state) => SafetySensorPairingMatchingPage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: SafetySensorPairingSuccessPage.routePath,
        builder: (context, state) => SafetySensorPairingSuccessPage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: SafetySensorPairingFailurePage.routePath,
        builder: (context, state) => SafetySensorPairingFailurePage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
    ],
  );
}

Future<void> _pumpRouter(
  WidgetTester tester,
  GoRouter router, {
  SafetySensorPairingRepository? pairingRepository,
  SafetySensorsEvaluationRepository? evaluationRepository,
}) async {
  final managementGateway = MockHardwareGateway()
    ..connectedBleDevices['mock-device'] = const ConnectedBleDevice(
      deviceId: 'mock-device',
      state: BleConnectionState.connected,
    );
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
            repository:
                evaluationRepository ??
                _FakeSafetySensorsEvaluationRepository(_testSafetyEvaluation),
          ),
        ),
        safetySensorPairingRepositoryProvider.overrideWithValue(
          pairingRepository ?? const _FakeSafetySensorPairingRepository(),
        ),
        safetySensorManagementHardwareGatewayProvider.overrideWithValue(
          managementGateway,
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
  SafetySensorsEvaluation? evaluation,
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
              evaluation ?? _testSafetyEvaluation,
            ),
          ),
        ),
        safetySensorPairingRepositoryProvider.overrideWithValue(
          const _FakeSafetySensorPairingRepository(),
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

class _FakeSafetySensorPairingRepository
    implements SafetySensorPairingRepository {
  const _FakeSafetySensorPairingRepository({
    this.status = SafetyAccessoryPairingStatus.success,
    this.reasonCode = 0,
    this.connected = true,
  });

  final SafetyAccessoryPairingStatus status;
  final int? reasonCode;
  final bool connected;

  @override
  Future<bool> isDeviceConnected({
    required String deviceId,
    required String requestId,
  }) async => connected;

  @override
  Future<SafetySensorPairingResult> pair(
    SafetySensorPairingRequest request,
  ) async => SafetySensorPairingResult(
    request: request,
    status: request.action == SafetyAccessoryPairingAction.cancel
        ? SafetyAccessoryPairingStatus.success
        : status,
    reasonCode: reasonCode,
  );
}

class _DisconnectedSafetySensorPairingRepository
    extends _FakeSafetySensorPairingRepository {
  const _DisconnectedSafetySensorPairingRepository() : super(connected: false);
}

class _PendingSafetySensorPairingRepository
    implements SafetySensorPairingRepository {
  final Completer<SafetySensorPairingResult> startCompleter =
      Completer<SafetySensorPairingResult>();
  final List<SafetyAccessoryPairingAction> actions =
      <SafetyAccessoryPairingAction>[];

  @override
  Future<bool> isDeviceConnected({
    required String deviceId,
    required String requestId,
  }) async => true;

  @override
  Future<SafetySensorPairingResult> pair(SafetySensorPairingRequest request) {
    actions.add(request.action);
    if (request.action == SafetyAccessoryPairingAction.start) {
      return startCompleter.future;
    }
    return Future<SafetySensorPairingResult>.value(
      SafetySensorPairingResult(
        request: request,
        status: SafetyAccessoryPairingStatus.success,
        reasonCode: 0,
      ),
    );
  }
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

class _CountingSafetySensorsEvaluationRepository
    implements SafetySensorsEvaluationRepository {
  _CountingSafetySensorsEvaluationRepository(this.evaluation);

  final SafetySensorsEvaluation evaluation;
  var fetchCount = 0;

  @override
  Future<SafetySensorsEvaluation> fetchEvaluation({
    required String doorId,
    required String requestId,
  }) async {
    fetchCount += 1;
    return evaluation;
  }
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
        statusLabel: 'Offline',
        batteryStatus: SafetySensorBatteryStatus.unknown,
        operationPoints: [],
      ),
      SafetySensor(
        id: 'WIRED_ELECTRONIC_LOCK',
        sensorCode: 'WIRED_ELECTRONIC_LOCK',
        status: SafetySensorStatus.locked,
        statusLabel: 'Locked',
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
        statusLabel: 'Triggered',
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
        statusLabel: 'Not triggered',
        batteryStatus: SafetySensorBatteryStatus.normal,
        operationPoints: [],
      ),
      const SafetySensor(
        id: 'WIRELESS_ELECTRONIC_LOCK',
        sensorCode: 'WIRELESS_ELECTRONIC_LOCK',
        status: SafetySensorStatus.locked,
        statusLabel: 'Locked',
        batteryStatus: SafetySensorBatteryStatus.normal,
        operationPoints: [],
      ),
      const SafetySensor(
        id: 'WIRELESS_SAFETY_EDGE',
        sensorCode: 'WIRELESS_SAFETY_EDGE',
        status: SafetySensorStatus.notTriggered,
        statusLabel: 'Not triggered',
        batteryStatus: SafetySensorBatteryStatus.normal,
        operationPoints: [],
      ),
      const SafetySensor(
        id: 'WIRELESS_SLACK_ROPE',
        sensorCode: 'WIRELESS_SLACK_ROPE',
        status: SafetySensorStatus.disconnected,
        statusLabel: 'Offline',
        batteryStatus: SafetySensorBatteryStatus.unknown,
        operationPoints: [],
      ),
    ],
  ),
);

final _activeMarkerSafetyEvaluation = SafetySensorsEvaluation(
  deviceId: 'active-sensor-device',
  totalSensorCount: 7,
  fineSensorCount: 7,
  abnormalSensorCount: 0,
  lowPowerSensorCount: 0,
  wiredSensorGroup: const SafetySensorGroup(
    status: SafetySensorGroupStatus.normal,
    sensors: [
      SafetySensor(
        id: 'WIRED_PHOTO_BEAM',
        sensorCode: 'WIRED_PHOTO_BEAM',
        status: SafetySensorStatus.notTriggered,
        batteryStatus: SafetySensorBatteryStatus.unknown,
        operationPoints: [],
      ),
      SafetySensor(
        id: 'WIRED_ELECTRONIC_LOCK',
        sensorCode: 'WIRED_ELECTRONIC_LOCK',
        status: SafetySensorStatus.notTriggered,
        batteryStatus: SafetySensorBatteryStatus.unknown,
        operationPoints: [],
      ),
    ],
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
      SafetySensor(
        id: 'WIRELESS_WICKET_DOOR',
        sensorCode: 'WIRELESS_WICKET_DOOR',
        status: SafetySensorStatus.notTriggered,
        batteryStatus: SafetySensorBatteryStatus.normal,
        operationPoints: [],
      ),
      SafetySensor(
        id: 'WIRELESS_ELECTRONIC_LOCK',
        sensorCode: 'WIRELESS_ELECTRONIC_LOCK',
        status: SafetySensorStatus.notTriggered,
        batteryStatus: SafetySensorBatteryStatus.normal,
        operationPoints: [],
      ),
      SafetySensor(
        id: 'WIRELESS_SAFETY_EDGE',
        sensorCode: 'WIRELESS_SAFETY_EDGE',
        status: SafetySensorStatus.notTriggered,
        batteryStatus: SafetySensorBatteryStatus.normal,
        operationPoints: [],
      ),
      SafetySensor(
        id: 'WIRELESS_SLACK_ROPE',
        sensorCode: 'WIRELESS_SLACK_ROPE',
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
