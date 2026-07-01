import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flinx/app/flinx_app.dart';

void main() {
  testWidgets('shows the unauthenticated welcome page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlinxApp()));

    await tester.pumpAndSettle();

    expect(find.text('Start your\nsmart life'), findsOneWidget);
    expect(find.text('Make your life comfortable'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}
