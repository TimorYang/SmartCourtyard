import 'package:flinx/app/flinx_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens scene page from the second home action', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlinxApp()));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Scene'));
    await tester.pumpAndSettle();

    expect(find.text('SCENE'), findsOneWidget);
    expect(find.byTooltip('Edit scene'), findsOneWidget);
    expect(find.text('5 Scenes'), findsOneWidget);
    expect(find.text('Warehouse A'), findsOneWidget);
    expect(find.text('5 Devices'), findsOneWidget);
    expect(find.text('Home Garage A'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('New scene'), findsOneWidget);
  });

  testWidgets('opens scene name dialog from new scene card', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlinxApp()));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Scene'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New scene'));
    await tester.pumpAndSettle();

    expect(find.text('Scene Name'), findsOneWidget);
    expect(find.text('Input scene name'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('confirm'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Scene Name'), findsNothing);

    await tester.tap(find.text('New scene'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Demo scene');
    await tester.tap(find.text('confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Scene Name'), findsNothing);
  });

  testWidgets('toggles scene editing mode from the top-right action', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FlinxApp()));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Scene'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit scene'));
    await tester.pumpAndSettle();

    expect(find.text('SCENE EDITING'), findsOneWidget);
    expect(find.byTooltip('Done editing'), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsNWidgets(3));
    expect(find.text('New scene'), findsNothing);

    await tester.tap(find.byTooltip('Done editing'));
    await tester.pumpAndSettle();

    expect(find.text('SCENE'), findsOneWidget);
    expect(find.byTooltip('Edit scene'), findsOneWidget);
  });
}
