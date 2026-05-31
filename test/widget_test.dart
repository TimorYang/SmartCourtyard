import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flinx/app/flinx_app.dart';

void main() {
  testWidgets('shows the FLINX home shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlinxApp()));

    await tester.pumpAndSettle();

    expect(find.text('FLINX'), findsOneWidget);
    expect(find.text('Garage Door'), findsOneWidget);
  });
}
