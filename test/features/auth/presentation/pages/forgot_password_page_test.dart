import 'package:flinx/app/flinx_app.dart';
import 'package:flinx/app/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openForgotPasswordPage(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlinxApp()));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot password'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the forgot password form', (tester) async {
    await openForgotPasswordPage(tester);

    expect(find.text('Forget Password?'), findsOneWidget);
    expect(
      find.text('Please enter the address associated your account'),
      findsOneWidget,
    );
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);
  });

  testWidgets('enables send code after email input', (tester) async {
    await openForgotPasswordPage(tester);

    FilledButton button = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(button.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('forgot_password_email_input')),
      'user@example.com',
    );
    await tester.pumpAndSettle();

    button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('shows an untitled alert for an invalid email', (tester) async {
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

    await openForgotPasswordPage(tester);

    await tester.enterText(
      find.byKey(const ValueKey('forgot_password_email_input')),
      'demo-account',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(alertCalls, hasLength(1));
    expect(alertCalls.single.method, 'showCustomAlert');
    expect(alertCalls.single.arguments, containsPair('windowTitle', ''));
    expect(
      alertCalls.single.arguments,
      containsPair('text', 'Enter a valid email address'),
    );
    expect(find.text('Enter Code'), findsNothing);
  });

  testWidgets('opens code, reset password, and success steps', (tester) async {
    await openForgotPasswordPage(tester);

    await tester.enterText(
      find.byKey(const ValueKey('forgot_password_email_input')),
      'user@example.com',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Enter Code'), findsOneWidget);
    expect(find.textContaining('use*****@e***'), findsOneWidget);
    expect(find.text('Send Again OTP (58s)'), findsOneWidget);

    final codeField = find.descendant(
      of: find.byKey(const ValueKey('forgot_password_code_pinput')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(codeField, '12a34b567');
    await tester.pump();

    final editableText = tester.widget<EditableText>(codeField);
    expect(editableText.controller.text, '123456');

    await tester.pumpAndSettle();

    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Set your password'), findsOneWidget);
    expect(find.text('Enter an 8-digit password'), findsOneWidget);
    expect(find.text('Enter the 8-digit password again'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('forgot_password_reset_password_input')),
        matching: find.byType(TextField),
      ),
      '12345678',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(
          const ValueKey('forgot_password_reset_confirm_password_input'),
        ),
        matching: find.byType(TextField),
      ),
      '12345678',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('forgot_password_success_icon')),
      findsOneWidget,
    );
    expect(find.text('Reset Succeeded'), findsOneWidget);
    expect(find.text('Password reset succeeded'), findsOneWidget);

    await tester.tap(find.text('Back to Login'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('Start your\nsmart life'), findsOneWidget);
  });

  testWidgets('resend OTP countdown enables resend and restarts after tap', (
    tester,
  ) async {
    await openForgotPasswordPage(tester);

    await tester.enterText(
      find.byKey(const ValueKey('forgot_password_email_input')),
      'user@example.com',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Send Again OTP (58s)'), findsOneWidget);

    TextButton resendButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Send Again OTP (58s)'),
    );
    expect(resendButton.onPressed, isNull);
    expect(
      resendButton.style?.foregroundColor?.resolve({WidgetState.disabled}),
      AppColors.textCodeResendDisabled,
    );

    await tester.pump(const Duration(seconds: 58));
    expect(find.text('Send Again OTP (0s)'), findsNothing);
    expect(find.text('Send Again OTP'), findsOneWidget);

    resendButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Send Again OTP'),
    );
    expect(resendButton.onPressed, isNotNull);
    expect(
      resendButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      AppColors.textCodeResend,
    );

    await tester.tap(find.text('Send Again OTP'));
    await tester.pump();

    expect(find.text('Send Again OTP (59s)'), findsOneWidget);
  });

  testWidgets('dismisses keyboard when tapping blank area', (tester) async {
    await openForgotPasswordPage(tester);

    final emailEditableText = find.descendant(
      of: find.byKey(const ValueKey('forgot_password_email_input')),
      matching: find.byType(EditableText),
    );
    await tester.tap(emailEditableText);
    await tester.pumpAndSettle();

    EditableText editableText = tester.widget<EditableText>(emailEditableText);
    expect(editableText.focusNode.hasFocus, isTrue);

    await tester.tap(find.text('Forget Password?'));
    await tester.pumpAndSettle();

    editableText = tester.widget<EditableText>(emailEditableText);
    expect(editableText.focusNode.hasFocus, isFalse);
  });
}
