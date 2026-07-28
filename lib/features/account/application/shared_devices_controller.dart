import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/shared_door.dart';
import '../domain/use_cases/fetch_shared_doors_use_case.dart';
import 'providers.dart';

class SharedDevicesController extends AsyncNotifier<List<SharedDoor>> {
  FetchSharedDoorsUseCase get _fetchSharedDoors =>
      ref.read(fetchSharedDoorsUseCaseProvider);

  @override
  Future<List<SharedDoor>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<SharedDoor>> _load() => _fetchSharedDoors(
    requestId:
        'shared-devices-${DateTime.now().toUtc().microsecondsSinceEpoch}',
  );
}
