import 'package:flinx/features/device_control/application/already_added_devices_controller.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/domain/entities/door_detail.dart';
import 'package:flinx/features/device_control/domain/repositories/door_detail_repository.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'loads only associated devices and does not paginate door detail',
    () async {
      final repository = _RecordingDoorDetailRepository(_doorDetail());
      final container = _container(repository);
      addTearDown(container.dispose);

      final controller = container.read(
        alreadyAddedDevicesControllerProvider.notifier,
      );
      await controller.loadInitial(doorId: '12');

      final state = container.read(alreadyAddedDevicesControllerProvider);
      expect(state.devices, hasLength(1));
      expect(state.devices.single.bleName, 'opener-001');
      expect(state.hasMore, isFalse);
      expect(repository.requestedDoorIds, ['12']);

      await controller.loadMore();
      expect(repository.requestedDoorIds, ['12']);
    },
  );

  test('refreshes the associated device collection', () async {
    final repository = _RecordingDoorDetailRepository(_doorDetail());
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      alreadyAddedDevicesControllerProvider.notifier,
    );

    await controller.loadInitial(doorId: '12');
    repository.detail = _doorDetail(bleName: 'opener-002');
    await controller.refresh(doorId: '12');

    final state = container.read(alreadyAddedDevicesControllerProvider);
    expect(state.devices.single.bleName, 'opener-002');
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

DoorDetail _doorDetail({String bleName = 'opener-001'}) {
  return DoorDetail(
    id: '12',
    name: 'Garage door',
    doorState: DoorState.closed,
    doorStateLabel: 'Closed',
    operatedCycles: 0,
    remainingCycles: 0,
    associatedDevices: [
      DoorAssociatedDevice(
        deviceType: 'opener',
        associated: true,
        primaryControl: true,
        bleName: bleName,
      ),
      const DoorAssociatedDevice(
        deviceType: 'dongle',
        associated: false,
        primaryControl: false,
        bleName: 'dongle-001',
      ),
    ],
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
}
