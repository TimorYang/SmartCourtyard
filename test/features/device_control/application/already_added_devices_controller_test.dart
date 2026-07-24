import 'package:flinx/features/device_control/application/already_added_devices_controller.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/domain/entities/door_detail.dart';
import 'package:flinx/features/device_control/domain/entities/door_device.dart';
import 'package:flinx/features/device_control/domain/repositories/door_detail_repository.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'returns an empty device list when door detail has no device collection',
    () async {
      final repository = _RecordingDoorDetailRepository(_doorDetail());
      final container = _container(repository);
      addTearDown(container.dispose);

      final controller = container.read(
        alreadyAddedDevicesControllerProvider.notifier,
      );
      await controller.loadInitial(doorId: '12');

      final state = container.read(alreadyAddedDevicesControllerProvider);
      expect(state.devices, isEmpty);
      expect(state.hasMore, isFalse);
      expect(repository.requestedDoorIds, ['12']);

      await controller.loadMore();
      expect(repository.requestedDoorIds, ['12']);
    },
  );

  test('keeps the device list empty after refresh', () async {
    final repository = _RecordingDoorDetailRepository(_doorDetail());
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      alreadyAddedDevicesControllerProvider.notifier,
    );

    await controller.loadInitial(doorId: '12');
    await controller.refresh(doorId: '12');

    final state = container.read(alreadyAddedDevicesControllerProvider);
    expect(state.devices, isEmpty);
    expect(repository.requestedDoorIds, ['12', '12']);
  });

  test(
    'exposes an initial-load failure when the detail request fails',
    () async {
      final repository = _RecordingDoorDetailRepository(_doorDetail())
        ..shouldFail = true;
      final container = _container(repository);
      addTearDown(container.dispose);

      await container
          .read(alreadyAddedDevicesControllerProvider.notifier)
          .loadInitial(doorId: '12');

      final state = container.read(alreadyAddedDevicesControllerProvider);
      expect(state.initialLoadFailed, isTrue);
      expect(state.isInitialLoading, isFalse);
    },
  );
}

ProviderContainer _container(_RecordingDoorDetailRepository repository) {
  return ProviderContainer(
    overrides: [doorDetailRepositoryProvider.overrideWithValue(repository)],
  );
}

DoorDetail _doorDetail() {
  return DoorDetail(
    id: '12',
    name: 'Garage door',
    doorState: DoorState.closed,
    doorStateLabel: 'Closed',
    operatedCycles: 0,
    remainingCycles: 0,
  );
}

class _RecordingDoorDetailRepository implements DoorDetailRepository {
  _RecordingDoorDetailRepository(this.detail);

  DoorDetail detail;
  bool shouldFail = false;
  final List<String> requestedDoorIds = <String>[];

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) async {
    requestedDoorIds.add(doorId);
    if (shouldFail) {
      throw StateError('network failure');
    }
    return detail;
  }

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) async => const [];
}
