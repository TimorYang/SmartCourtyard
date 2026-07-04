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
    expect(find.text('5 Scenes'), findsOneWidget);
    expect(find.text('Warehouse A'), findsOneWidget);
    expect(find.text('5 Devices'), findsOneWidget);
    expect(find.text('Home Garage A'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('New scene'), findsOneWidget);
  });
}
