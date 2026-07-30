import 'dart:async';

import 'package:flinx/features/account/application/account_deletion_controller.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prevents duplicate account deletion submissions', () async {
    final completion = Completer<void>();
    final repository = _DeletionAccountRepository(
      onConfirm: ({required requestId}) => completion.future,
    );
    final container = ProviderContainer(
      overrides: [accountRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final controller = container.read(
      accountDeletionControllerProvider.notifier,
    );
    final firstAttempt = controller.confirm();

    expect(await controller.confirm(), isFalse);
    expect(repository.requestIds, hasLength(1));

    completion.complete();
    expect(await firstAttempt, isTrue);
  });
}

class _DeletionAccountRepository implements AccountRepository {
  _DeletionAccountRepository({required this.onConfirm});

  final Future<void> Function({required String requestId}) onConfirm;
  final List<String> requestIds = [];

  @override
  Future<void> confirmAccountDeletion({required String requestId}) {
    requestIds.add(requestId);
    return onConfirm(requestId: requestId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
