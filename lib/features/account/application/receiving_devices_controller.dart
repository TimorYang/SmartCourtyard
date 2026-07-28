import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<List<ReceivingDoor>> _load() => _fetchReceivingDoors(
    requestId:
        'receiving-devices-${DateTime.now().toUtc().microsecondsSinceEpoch}',
  );
}
