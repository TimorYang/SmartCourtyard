import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../domain/entities/door_share.dart';
import 'providers.dart';

class DoorShareSubmitState {
  const DoorShareSubmitState({this.isSubmitting = false, this.error});
  final bool isSubmitting;
  final AppError? error;
}

class DoorShareController extends Notifier<DoorShareSubmitState> {
  @override
  DoorShareSubmitState build() => const DoorShareSubmitState();

  Future<bool> submit({
    required int doorId,
    required CreateDoorShareCommand command,
  }) async {
    if (state.isSubmitting) return false;
    state = const DoorShareSubmitState(isSubmitting: true);
    final requestId =
        'door-share-create-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await ref.read(createDoorShareUseCaseProvider)(
        doorId: doorId,
        command: command,
        requestId: requestId,
      );
      state = const DoorShareSubmitState();
      return true;
    } on AppError catch (error) {
      state = DoorShareSubmitState(error: error);
      return false;
    } catch (_) {
      state = DoorShareSubmitState(
        error: AppError(
          code: AppErrorCode.unknown,
          messageKey: 'doorShare.failed',
          action: AppErrorAction.retry,
          requestId: requestId,
          retryable: true,
        ),
      );
      return false;
    }
  }

  Future<bool> update({
    required int shareId,
    required UpdateDoorShareCommand command,
  }) async {
    if (state.isSubmitting) return false;
    state = const DoorShareSubmitState(isSubmitting: true);
    final requestId =
        'door-share-update-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await ref.read(updateDoorShareUseCaseProvider)(
        shareId: shareId,
        command: command,
        requestId: requestId,
      );
      state = const DoorShareSubmitState();
      return true;
    } on AppError catch (error) {
      state = DoorShareSubmitState(error: error);
      return false;
    } catch (_) {
      state = DoorShareSubmitState(
        error: AppError(
          code: AppErrorCode.unknown,
          messageKey: 'doorShare.failed',
          action: AppErrorAction.retry,
          requestId: requestId,
          retryable: true,
        ),
      );
      return false;
    }
  }
}

final doorShareCapabilitiesProvider = FutureProvider.autoDispose
    .family<List<ShareCapability>, int>((ref, doorId) {
      return ref.watch(fetchDoorShareCapabilitiesUseCaseProvider)(
        doorId: doorId,
        requestId:
            'door-share-capabilities-$doorId-${DateTime.now().toUtc().microsecondsSinceEpoch}',
      );
    });

final doorShareControllerProvider =
    NotifierProvider<DoorShareController, DoorShareSubmitState>(
      DoorShareController.new,
    );
