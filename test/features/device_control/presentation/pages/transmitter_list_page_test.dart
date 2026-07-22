import 'package:flinx/features/device_control/presentation/pages/transmitter_list_page.dart';
import 'package:flinx/features/device_control/presentation/pages/transmitter_learning_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders the transmitter management design and actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TransmitterListPage(deviceId: 'mock-device'),
      ),
    );

    expect(find.text('Management'), findsOneWidget);
    expect(find.text('Warehouse-01-Daniel'), findsOneWidget);
    expect(find.text('Workshop-03-Airly'), findsOneWidget);
    expect(find.text('Tips'), findsOneWidget);
    expect(find.bySemanticsLabel('Edit transmitter'), findsNWidgets(4));
    expect(find.bySemanticsLabel('Delete transmitter'), findsNWidgets(4));
    expect(find.bySemanticsLabel('Add transmitter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the transmitter name sheet from the edit action', (
    tester,
  ) async {
    await _pumpPage(tester);

    await tester.tap(find.bySemanticsLabel('Edit transmitter').first);
    await tester.pumpAndSettle();

    expect(find.text('Transmitter info'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Transmitter info'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the delete confirmation sheet from the delete action', (
    tester,
  ) async {
    await _pumpPage(tester);

    await tester.tap(find.bySemanticsLabel('Delete transmitter').first);
    await tester.pumpAndSettle();

    expect(find.text('Prompt'), findsOneWidget);
    expect(
      find.text('Please confirm whether you want to delete the transmitter'),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
  });

  testWidgets('opens transmitter learning from the add action', (tester) async {
    final router = GoRouter(
      initialLocation: '${TransmitterListPage.routePath}?deviceId=mock-device',
      routes: [
        GoRoute(
          path: TransmitterListPage.routePath,
          builder: (_, state) => TransmitterListPage(
            deviceId: state.uri.queryParameters['deviceId'] ?? '',
          ),
        ),
        GoRoute(
          path: TransmitterLearningPage.routePath,
          builder: (_, state) => TransmitterLearningPage(
            deviceId: state.uri.queryParameters['deviceId'] ?? '',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Add transmitter'));
    await tester.pumpAndSettle();

    expect(find.byType(TransmitterLearningPage), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.queryParameters['deviceId'], 'mock-device');
  });
}

Future<void> _pumpPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const TransmitterListPage(deviceId: 'mock-device'),
    ),
  );
  await tester.pumpAndSettle();
}
