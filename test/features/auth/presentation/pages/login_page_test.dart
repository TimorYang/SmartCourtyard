import 'package:flinx/app/flinx_app.dart';
import 'package:flinx/features/auth/application/login_form_controller.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/presentation/widgets/auth_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openLoginPage(
    WidgetTester tester, {
    bool appleSupported = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appleLoginPlatformSupportedProvider.overrideWithValue(appleSupported),
        ],
        child: const FlinxApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'renders the login form with default credentials and third-party sign-in options',
    (tester) async {
      await openLoginPage(tester);

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields[0].controller?.text, defaultLoginAccount);
      expect(fields[1].controller?.text, defaultLoginPassword);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Other ways to login'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Continue Sign in with Apple'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Continue Sign in with Google'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Continue Sign in with Facebook'),
        findsOneWidget,
      );
    },
  );

  testWidgets('requires agreement before starting Apple login', (tester) async {
    await openLoginPage(tester);

    await tester.tap(find.byKey(const ValueKey('apple_login_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Please agree to the User Agreement and Privacy Policy first.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('hides Apple login when the platform is unsupported', (
    tester,
  ) async {
    await openLoginPage(tester, appleSupported: false);

    expect(find.byKey(const ValueKey('apple_login_button')), findsNothing);
    expect(find.bySemanticsLabel('Continue Sign in with Apple'), findsNothing);
  });

  testWidgets('keeps third-party sign-in fixed when keyboard insets change', (
    tester,
  ) async {
    addTearDown(tester.view.resetViewInsets);
    await openLoginPage(tester);

    final appleButton = find.bySemanticsLabel('Continue Sign in with Apple');
    final initialTop = tester.getTopLeft(appleButton).dy;

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pump();

    expect(tester.getTopLeft(appleButton).dy, initialTop);
  });

  testWidgets('clears the account and toggles password visibility', (
    tester,
  ) async {
    await openLoginPage(tester);

    var fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    final accountField = find.byType(AuthTextField).first;
    final initialAccountFieldSize = tester.getSize(accountField);
    expect(fields[0].controller?.text, isEmpty);
    expect(fields[1].obscureText, isTrue);
    expect(find.bySemanticsLabel('Clear account').hitTestable(), findsNothing);

    await tester.enterText(find.byType(TextField).at(0), 'demo@example.com');
    await tester.pump();
    expect(
      find.bySemanticsLabel('Clear account').hitTestable(),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Clear account'));
    await tester.pump();
    fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller?.text, isEmpty);
    expect(find.bySemanticsLabel('Clear account').hitTestable(), findsNothing);
    expect(tester.getSize(accountField), initialAccountFieldSize);

    await tester.enterText(find.byType(TextField).at(0), 'demo@example.com');
    await tester.pump();
    expect(
      find.bySemanticsLabel('Clear account').hitTestable(),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).at(1), 'demo-password');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Show password'));
    await tester.pump();
    fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[1].obscureText, isFalse);
    expect(fields[1].controller?.text, 'demo-password');
    expect(find.bySemanticsLabel('Hide password'), findsOneWidget);
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

    await tester.tap(find.text('Sign in'));
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
