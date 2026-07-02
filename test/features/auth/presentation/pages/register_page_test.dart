import 'package:flinx/app/flinx_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openRegisterPage(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlinxApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the register form', (tester) async {
    await openRegisterPage(tester);

    expect(find.text('Register'), findsOneWidget);
    expect(
      find.text('Please enter the address associated your account'),
      findsOneWidget,
    );
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(
      find.textContaining('I have read and agreed', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Privacy Policy', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Send code'), findsOneWidget);
  });

  testWidgets('enables send code only after email and privacy agreement', (
    tester,
  ) async {
    await openRegisterPage(tester);

    FilledButton button = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(button.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.pumpAndSettle();

    button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);

    final privacyToggle = find.byKey(
      const ValueKey('register_privacy_agreement_toggle'),
    );

    await tester.tap(privacyToggle);
    await tester.pumpAndSettle();

    button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.tap(privacyToggle);
    await tester.pumpAndSettle();

    button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(find.text('Verification code is not connected yet'), findsOneWidget);
  });
}
