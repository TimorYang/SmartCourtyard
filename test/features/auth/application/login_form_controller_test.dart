import 'package:flinx/features/auth/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer createContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('empty email cannot submit', () {
    final container = createContainer();
    final controller = container.read(loginFormControllerProvider.notifier);

    controller.updatePassword('demo-password');
    controller.toggleAgreement();

    final state = container.read(loginFormControllerProvider);
    expect(state.canSubmit, isFalse);
  });

  test('invalid email can press submit but fails submit validation', () {
    final container = createContainer();
    final controller = container.read(loginFormControllerProvider.notifier);

    controller.updateAccount('demo-account');
    controller.updatePassword('demo-password');
    controller.toggleAgreement();

    final stateBeforeSubmit = container.read(loginFormControllerProvider);
    expect(stateBeforeSubmit.canSubmit, isTrue);

    final isValid = controller.validateEmailForSubmit();

    final stateAfterSubmit = container.read(loginFormControllerProvider);
    expect(isValid, isFalse);
    expect(stateAfterSubmit.canSubmit, isTrue);
  });

  test('valid email, password, and agreement can submit', () {
    final container = createContainer();
    final controller = container.read(loginFormControllerProvider.notifier);

    controller.updateAccount('user@example.com');
    controller.updatePassword('demo-password');
    controller.toggleAgreement();

    final state = container.read(loginFormControllerProvider);
    expect(controller.validateEmailForSubmit(), isTrue);
    expect(state.canSubmit, isTrue);
  });

  test('email is trimmed before validation', () {
    final container = createContainer();
    final controller = container.read(loginFormControllerProvider.notifier);

    controller.updateAccount('  user@example.com  ');
    controller.updatePassword('demo-password');
    controller.toggleAgreement();

    final state = container.read(loginFormControllerProvider);
    expect(state.trimmedEmail, 'user@example.com');
    expect(state.canSubmit, isTrue);
  });
}
