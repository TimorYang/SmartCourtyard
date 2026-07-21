import 'dart:typed_data';

import 'package:flinx/core/platform/gallery_image_saver.dart';
import 'package:flinx/features/security_center/presentation/pages/full_report_page.dart';
import 'package:flinx/features/security_center/presentation/pages/general_evaluation_page.dart';
import 'package:flinx/features/security_center/presentation/pages/security_center_page.dart';
import 'package:flinx/features/security_center/presentation/pages/safety_sensors_evaluation_page.dart';
import 'package:flinx/features/security_center/presentation/widgets/security_report_widgets.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
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

    expect(find.text('Full Report'), findsOneWidget);
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

    await tester.tap(
      find.byKey(const ValueKey<String>('segment-Close evaluation')),
    );
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

  testWidgets('full report contains all sections and safety suggestions', (
    tester,
  ) async {
    await _pumpPage(tester, const FullReportPage(deviceId: 'mock-device'));

    expect(find.text('Door balance evaluation'), findsNWidgets(2));
    expect(find.text('Door operation record'), findsNWidgets(2));
    expect(find.text('Motor function status'), findsOneWidget);
    expect(find.text('Wired sensor status'), findsOneWidget);
    expect(find.text('Wireless Sensors Status'), findsOneWidget);
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

  testWidgets('full report save captures report image and shows success', (
    tester,
  ) async {
    var saveCalls = 0;
    Uint8List? savedBytes;

    await _pumpPage(
      tester,
      FullReportPage(
        deviceId: 'mock-device',
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
    await tester.pumpAndSettle();

    expect(saveCalls, 1);
    expect(savedBytes, isNotNull);
    expect(savedBytes, isNotEmpty);
    expect(find.text('Report saved to album.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full report save failure shows a readable error', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      FullReportPage(
        deviceId: 'mock-device',
        captureReportImage: (_, _) async => Uint8List.fromList([1, 2, 3]),
        saveReportImage: (_) async {
          throw const GalleryImageSaveException(GalleryImageSaveFailure.failed);
        },
      ),
    );

    _tapReportSaveAction(tester);
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Unable to save report image.'), findsOneWidget);
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
        captureReportImage: (_, _) async {
          throw StateError('capture unavailable');
        },
        saveReportImage: (_) async {},
      ),
    );

    _tapReportSaveAction(tester);
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Unable to create report image.'), findsOneWidget);
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
      const SafetySensorsEvaluationPage(deviceId: 'sensor-device'),
    );

    expect(find.text('Sensors'), findsOneWidget);
    expect(find.text('Fine'), findsOneWidget);
    expect(find.text('Abnormal'), findsOneWidget);
    expect(find.text('Low power'), findsOneWidget);
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
    expect(find.text('Disconnect'), findsNWidgets(6));

    await tester.scrollUntilVisible(
      find.text('Wireless safety edge'),
      500,
      scrollable: _scrollableInside('safety-sensors-scroll-sensor-device'),
    );
    expect(find.text('Wireless safety edge'), findsOneWidget);
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
      const SafetySensorsEvaluationPage(deviceId: 'compact-device'),
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
        builder: (context, state) =>
            SecurityCenterPage(deviceId: 'mock-device', onTabSelected: (_) {}),
      ),
      GoRoute(
        path: FullReportPage.routePath,
        name: FullReportPage.routeName,
        builder: (context, state) => FullReportPage(
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
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
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
}) async {
  if (setViewport) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}
