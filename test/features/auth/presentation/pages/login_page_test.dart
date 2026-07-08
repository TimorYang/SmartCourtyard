import 'package:flinx/app/flinx_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openLoginPage(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlinxApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the login form and third-party sign-in options', (
    tester,
  ) async {
    await openLoginPage(tester);

    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter password'), findsOneWidget);
    expect(find.text('Login in'), findsOneWidget);
    expect(find.text('Continue Sign in with Apple'), findsOneWidget);
    expect(find.text('Continue Sign in with Google'), findsOneWidget);
    expect(find.text('Continue Sign in with Alexa'), findsOneWidget);
  });

  testWidgets('keeps third-party sign-in fixed when keyboard insets change', (
    tester,
  ) async {
    addTearDown(tester.view.resetViewInsets);
    await openLoginPage(tester);

    final appleButton = find.text('Continue Sign in with Apple');
    final initialTop = tester.getTopLeft(appleButton).dy;

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pump();

    expect(tester.getTopLeft(appleButton).dy, initialTop);
  });

  testWidgets('validates email format when login in is tapped', (tester) async {
    const alertChannel = MethodChannel('flutter_platform_alert');
    final alertCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      alertChannel,
      (call) async {
        alertCalls.add(call);
        return 'positive_button';
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        alertChannel,
        null,
      ),
    );

    await openLoginPage(tester);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(0), 'demo-account');
    await tester.enterText(find.byType(TextField).at(1), 'demo-password');
    await tester.tap(find.byKey(const ValueKey('login_agreement_toggle')));
    await tester.pumpAndSettle();

    final disabledButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(disabledButton.onPressed, isNotNull);
    expect(find.text('Enter a valid email address'), findsNothing);

    await tester.tap(find.text('Login in'));
    await tester.pumpAndSettle();

    expect(alertCalls, hasLength(1));
    expect(alertCalls.single.method, 'showCustomAlert');
    expect(
      alertCalls.single.arguments,
      containsPair('text', 'Enter a valid email address'),
    );
    expect(alertCalls.single.arguments, containsPair('windowTitle', ''));
    expect(find.text('Login is not connected yet'), findsNothing);
  });

  testWidgets(
    'simulates login and opens home after a valid email is submitted',
    (tester) async {
      await openLoginPage(tester);

      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'demo-password');
      await tester.tap(find.byKey(const ValueKey('login_agreement_toggle')));
      await tester.pumpAndSettle();

      final enabledButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(enabledButton.onPressed, isNotNull);

      await tester.tap(find.text('Login in'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('2 Doors'), findsOneWidget);
      expect(find.text('Garage door'), findsOneWidget);
      expect(find.text('Login is not connected yet'), findsNothing);
    },
  );

  testWidgets('navigates to register page and forgot password form', (
    tester,
  ) async {
    await openLoginPage(tester);

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot password'));
    await tester.pumpAndSettle();
    expect(find.text('Forget Password?'), findsOneWidget);
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);
  });
}
