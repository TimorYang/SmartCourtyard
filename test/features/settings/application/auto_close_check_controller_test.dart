import 'dart:async';

import 'package:flinx/features/settings/application/auto_close_check_controller.dart';
import 'package:flinx/features/settings/application/providers.dart';
import 'package:flinx/features/settings/domain/entities/auto_close_check_result.dart';
import 'package:flinx/features/settings/domain/repositories/auto_close_check_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores an allowed result for a request family key', () async {
    final repository = _FakeAutoCloseCheckRepository(
      result: const AutoCloseCheckResult(autoCloseAllowed: true),
    );
    final container = _createContainer(repository);
    addTearDown(container.dispose);
    final provider = autoCloseCheckControllerProvider((
      doorId: '10001',
      deviceId: '20001',
    ));
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    expect(await container.read(provider.notifier).checkAllowed(), isTrue);
    expect(container.read(provider).checking, isFalse);
    expect(container.read(provider).autoCloseAllowed, isTrue);
    expect(container.read(provider).hasError, isFalse);
    expect(repository.requests.single, ('10001', '20001'));
  });

  test(
    'fails closed and exposes an error state when the check fails',
    () async {
      final container = _createContainer(
        _FakeAutoCloseCheckRepository(error: StateError('unavailable')),
      );
      addTearDown(container.dispose);
      final provider = autoCloseCheckControllerProvider((
        doorId: '10001',
        deviceId: '20001',
      ));
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      expect(await container.read(provider.notifier).checkAllowed(), isFalse);
      expect(container.read(provider).checking, isFalse);
      expect(container.read(provider).autoCloseAllowed, isNull);
      expect(container.read(provider).hasError, isTrue);
    },
  );

  test('rejects duplicate checks while the first request is pending', () async {
    final completer = Completer<AutoCloseCheckResult>();
    final repository = _FakeAutoCloseCheckRepository(completer: completer);
    final container = _createContainer(repository);
    addTearDown(container.dispose);
    final provider = autoCloseCheckControllerProvider((
      doorId: '10001',
      deviceId: '20001',
    ));
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    final controller = container.read(provider.notifier);

    final first = controller.checkAllowed();
    expect(container.read(provider).checking, isTrue);
    expect(await controller.checkAllowed(), isFalse);
    expect(repository.callCount, 1);

    completer.complete(const AutoCloseCheckResult(autoCloseAllowed: false));
    expect(await first, isFalse);
    expect(container.read(provider).checking, isFalse);
    expect(container.read(provider).autoCloseAllowed, isFalse);
  });
}

ProviderContainer _createContainer(AutoCloseCheckRepository repository) {
  return ProviderContainer(
    overrides: [autoCloseCheckRepositoryProvider.overrideWithValue(repository)],
  );
}

class _FakeAutoCloseCheckRepository implements AutoCloseCheckRepository {
  _FakeAutoCloseCheckRepository({this.result, this.error, this.completer});

  final AutoCloseCheckResult? result;
  final Object? error;
  final Completer<AutoCloseCheckResult>? completer;
  final requests = <(String, String)>[];
  var callCount = 0;

  @override
  Future<AutoCloseCheckResult> checkAutoClose({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) async {
    callCount++;
    requests.add((doorId, deviceId));
    if (completer != null) return completer!.future;
    if (error != null) throw error!;
    return result!;
  }
}
