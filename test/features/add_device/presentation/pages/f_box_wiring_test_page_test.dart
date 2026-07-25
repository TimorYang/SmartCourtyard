import 'package:flinx/app/theme/app_design_tokens.dart';
import 'package:flinx/features/add_device/presentation/pages/f_box_wiring_test_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the PB wiring state and records a local test action', (
    tester,
  ) async {
    await _pumpPage(tester);

    expect(find.text('Test'), findsOneWidget);
    expect(find.text('PB wiring'), findsOneWidget);
    expect(find.text('O/S/C wiring'), findsOneWidget);
    expect(find.byKey(const Key('fBoxWiringTestPbControl')), findsOneWidget);
    expect(find.byKey(const Key('fBoxWiringTestOpenControl')), findsNothing);
    expect(find.text('door operates normally'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);

    expect(_statusColor(tester), AppColors.fBoxWiringTestStatusPending);
    await tester.tap(find.byKey(const Key('fBoxWiringTestPbControl')));
    await tester.pump();
    expect(_statusColor(tester), AppColors.brandPrimary);
  });

  testWidgets('switches to O/S/C controls and leaves NEXT local', (tester) async {
    await _pumpPage(tester);

    await tester.tap(find.byKey(const Key('fBoxWiringTestOscSegment')));
    await tester.pump();

    expect(find.byKey(const Key('fBoxWiringTestPbControl')), findsNothing);
    expect(find.byKey(const Key('fBoxWiringTestOpenControl')), findsOneWidget);
    expect(find.byKey(const Key('fBoxWiringTestStopControl')), findsOneWidget);
    expect(find.byKey(const Key('fBoxWiringTestCloseControl')), findsOneWidget);

    await tester.tap(find.byKey(const Key('fBoxWiringTestStopControl')));
    await tester.pump();
    expect(_statusColor(tester), AppColors.brandPrimary);

    await tester.tap(find.byKey(const Key('fBoxWiringTestNextButton')));
    await tester.pump();
    expect(find.byType(FBoxWiringTestPage), findsOneWidget);
  });

  testWidgets('renders the Chinese copy', (tester) async {
    await _pumpPage(tester, locale: const Locale('zh'));

    expect(find.text('测试'), findsOneWidget);
    expect(find.text('PB 接线'), findsOneWidget);
    expect(find.text('门体正常运行'), findsOneWidget);
  });
}

Color _statusColor(WidgetTester tester) {
  final indicator = tester.widget<Container>(
    find.byKey(const Key('fBoxWiringTestStatusIndicator')),
  );
  return (indicator.decoration! as BoxDecoration).color!;
}

Future<void> _pumpPage(WidgetTester tester, {Locale? locale}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const FBoxWiringTestPage(),
    ),
  );
  await tester.pumpAndSettle();
}
