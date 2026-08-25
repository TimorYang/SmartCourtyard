import 'package:flinx/core/network/server_business_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emits repeated server messages as distinct events', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(serverBusinessMessageProvider.notifier);

    controller.show(code: 100005, message: ' Account already exists. ');
    final first = container.read(serverBusinessMessageProvider)!;
    controller.show(code: 100005, message: 'Account already exists.');
    final second = container.read(serverBusinessMessageProvider)!;

    expect(first.message, 'Account already exists.');
    expect(first.code, 100005);
    expect(second.sequence, greaterThan(first.sequence));
  });
}
