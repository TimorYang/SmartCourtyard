import 'package:flinx/app/flinx_app.dart';
import 'package:flinx/app/theme/app_design_tokens.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/registration_verification.dart';
import 'package:flinx/features/auth/domain/repositories/auth_registration_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openRegisterPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRegistrationRepositoryProvider.overrideWithValue(
            _SuccessfulRegistrationRepository(),
          ),
        ],
        child: const FlinxApp(),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
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
    expect(button.onPressed, isNull);

    final privacyToggle = find.byKey(
      const ValueKey('register_privacy_agreement_toggle'),
    );

    await tester.tap(privacyToggle);
    await tester.pumpAndSettle();

    button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(privacyToggle);
    await tester.pumpAndSettle();

    button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.tap(privacyToggle);
    await tester.pumpAndSettle();

    button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Enter Code'), findsOneWidget);
    expect(find.textContaining('use*****@e***'), findsOneWidget);
    expect(find.text('Send Again OTP (58s)'), findsOneWidget);
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

    await openRegisterPage(tester);

    await tester.enterText(find.byType(TextField), 'demo-account');
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('register_privacy_agreement_toggle')),
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

  testWidgets(
    'verification code input accepts digits only and opens password step',
    (tester) async {
      await openRegisterPage(tester);

      await tester.enterText(find.byType(TextField), 'user@example.com');
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('register_privacy_agreement_toggle')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send code'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final codeField = find.descendant(
        of: find.byKey(const ValueKey('register_code_pinput')),
        matching: find.byType(EditableText),
      );
      await tester.enterText(codeField, '12a34b567');
      await tester.pump();

      final editableText = tester.widget<EditableText>(codeField);
      expect(editableText.controller.text, '123456');

      await tester.pumpAndSettle();

      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Set your password'), findsOneWidget);
      expect(find.text('Enter password'), findsOneWidget);
      expect(find.text('Enter password again'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(
        find.text(
          'Contain at least one lowercase letter, one uppercase letter, and one '
          'number, with a length between 8 and 16 characters.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('resend OTP countdown enables resend and restarts after tap', (
    tester,
  ) async {
    await openRegisterPage(tester);

    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('register_privacy_agreement_toggle')),
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

  testWidgets('password step requires matching passwords that meet the rule', (
    tester,
  ) async {
    await openRegisterPage(tester);

    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('register_privacy_agreement_toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final codeField = find.descendant(
      of: find.byKey(const ValueKey('register_code_pinput')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(codeField, '123456');
    await tester.pumpAndSettle();

    final passwordField = find.descendant(
      of: find.byKey(const ValueKey('register_password_input')),
      matching: find.byType(TextField),
    );
    final confirmPasswordField = find.descendant(
      of: find.byKey(const ValueKey('register_confirm_password_input')),
      matching: find.byType(TextField),
    );

    FilledButton button = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(button.onPressed, isNull);

    await tester.enterText(passwordField, 'password123');
    await tester.pump();

    expect(find.bySemanticsLabel('Show password'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Show password'));
    await tester.pump();

    final passwordTextField = tester.widget<TextField>(passwordField);
    expect(passwordTextField.obscureText, isFalse);

    await tester.enterText(confirmPasswordField, '12345670');
    await tester.pumpAndSettle();

    final editablePassword = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('register_password_input')),
        matching: find.byType(EditableText),
      ),
    );
    expect(editablePassword.controller.text, 'password123');

    button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.enterText(confirmPasswordField, 'Password123');
    await tester.pumpAndSettle();

    button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.enterText(passwordField, 'Password123');
    await tester.pumpAndSettle();

    button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('register_password_input')),
      findsOneWidget,
    );
  });

  testWidgets('password step dismisses keyboard when tapping blank area', (
    tester,
  ) async {
    await openRegisterPage(tester);

    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('register_privacy_agreement_toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final codeField = find.descendant(
      of: find.byKey(const ValueKey('register_code_pinput')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(codeField, '123456');
    await tester.pumpAndSettle();

    final passwordEditableText = find.descendant(
      of: find.byKey(const ValueKey('register_password_input')),
      matching: find.byType(EditableText),
    );
    await tester.tap(passwordEditableText);
    await tester.pumpAndSettle();

    EditableText editableText = tester.widget<EditableText>(
      passwordEditableText,
    );
    expect(editableText.focusNode.hasFocus, isTrue);

    await tester.tap(find.text('Set your password'));
    await tester.pumpAndSettle();

    editableText = tester.widget<EditableText>(passwordEditableText);
    expect(editableText.focusNode.hasFocus, isFalse);
  });
}

class _SuccessfulRegistrationRepository implements AuthRegistrationRepository {
  @override
  Future<void> completeRegistration({
    required String registrationToken,
    required String passwordCiphertext,
    required String confirmPasswordCiphertext,
    required String keyId,
    required String nonce,
    required String locale,
    required String timezone,
    String? regionCode,
    required String requestId,
  }) async {}

  @override
  Future<void> sendEmailCode({
    required String email,
    required String requestId,
  }) async {}

  @override
  Future<RegistrationVerification> verifyEmailCode({
    required String email,
    required String code,
    required String requestId,
  }) async => const RegistrationVerification(
    registrationToken: 'test-registration-token',
    expiresIn: Duration(minutes: 5),
  );
}
