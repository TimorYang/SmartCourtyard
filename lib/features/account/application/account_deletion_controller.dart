import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/use_cases/confirm_account_deletion_use_case.dart';
import 'providers.dart';

class AccountDeletionController extends AsyncNotifier<void> {
  late final ConfirmAccountDeletionUseCase _confirmAccountDeletion;

  @override
  void build() {
    _confirmAccountDeletion = ref.watch(confirmAccountDeletionUseCaseProvider);
  }

  Future<bool> confirm() async {
    if (state.isLoading) return false;

    state = const AsyncLoading<void>();
    try {
      await _confirmAccountDeletion(
        requestId: 'account-deletion-${DateTime.now().microsecondsSinceEpoch}',
      );
      state = const AsyncData<void>(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      return false;
    }
  }
}
