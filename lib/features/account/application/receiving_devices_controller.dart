import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../domain/entities/receiving_door.dart';
import '../domain/use_cases/fetch_receiving_doors_use_case.dart';
import 'providers.dart';

class ReceivingDevicesController extends AsyncNotifier<List<ReceivingDoor>> {
  FetchReceivingDoorsUseCase get _fetchReceivingDoors =>
      ref.read(fetchReceivingDoorsUseCaseProvider);

  @override
  Future<List<ReceivingDoor>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<AppError?> deleteShare({required int shareId}) async {
    final requestId =
        'receiving-device-delete-$shareId-'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await ref.read(deleteSharedDoorMemberUseCaseProvider)(
        shareId: shareId,
        requestId: requestId,
      );
      return null;
    } on AppError catch (error) {
      return error;
    }
  }

  Future<List<ReceivingDoor>> _load() => _fetchReceivingDoors(
    requestId:
        'receiving-devices-${DateTime.now().toUtc().microsecondsSinceEpoch}',
  );
}
