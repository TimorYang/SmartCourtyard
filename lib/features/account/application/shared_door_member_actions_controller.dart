import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import 'providers.dart';

class SharedDoorMemberActionsController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<AppError?> delete({required int shareId}) async {
    if (state) return null;
    state = true;
    final requestId =
        'shared-door-member-delete-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await ref.read(deleteSharedDoorMemberUseCaseProvider)(
        shareId: shareId,
        requestId: requestId,
      );
      return null;
    } on AppError catch (error) {
      return error;
    } finally {
      state = false;
    }
  }
}

final sharedDoorMemberActionsControllerProvider =
    NotifierProvider<SharedDoorMemberActionsController, bool>(
      SharedDoorMemberActionsController.new,
    );
