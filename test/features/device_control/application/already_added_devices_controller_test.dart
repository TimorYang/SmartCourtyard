import 'package:flinx/features/device_control/application/already_added_devices_controller.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/domain/entities/door_detail.dart';
import 'package:flinx/features/device_control/domain/entities/door_device.dart';
import 'package:flinx/features/device_control/domain/repositories/door_detail_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads the door devices returned by the device-list endpoint', () async {
    final repository = _RecordingDoorDetailRepository(devices: [_device()]);
    final container = _container(repository);
    addTearDown(container.dispose);

    final controller = container.read(
      alreadyAddedDevicesControllerProvider.notifier,
    );
    await controller.loadInitial(doorId: '12');

    final state = container.read(alreadyAddedDevicesControllerProvider);
    expect(state.devices, hasLength(1));
    expect(state.devices.single.deviceId, 'device-1');
    expect(state.hasMore, isFalse);
    expect(repository.requestedDeviceDoorIds, ['12']);

    await controller.loadMore();
    expect(repository.requestedDeviceDoorIds, ['12']);
  });

  test('refreshes the device list from the device-list endpoint', () async {
    final repository = _RecordingDoorDetailRepository(devices: const []);
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      alreadyAddedDevicesControllerProvider.notifier,
    );

    await controller.loadInitial(doorId: '12');
    await controller.refresh(doorId: '12');

    final state = container.read(alreadyAddedDevicesControllerProvider);
    expect(state.devices, isEmpty);
    expect(repository.requestedDeviceDoorIds, ['12', '12']);
  });

  test(
    'exposes an initial-load failure when the device-list request fails',
    () async {
      final repository = _RecordingDoorDetailRepository(devices: const [])
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

  test('unbinds a device and refreshes the current door device list', () async {
    final repository = _RecordingDoorDetailRepository(devices: [_device()]);
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      alreadyAddedDevicesControllerProvider.notifier,
    );

    await controller.loadInitial(doorId: '12');
    repository.devices = const [];
    await controller.unbindDevice(doorId: '12', deviceId: '1');

    final state = container.read(alreadyAddedDevicesControllerProvider);
    expect(repository.unboundDeviceIds, ['1']);
    expect(repository.requestedDeviceDoorIds, ['12', '12']);
    expect(state.devices, isEmpty);
    expect(state.pendingUnbindDeviceId, isNull);
  });

  test('keeps the list and exposes a failure when unbinding fails', () async {
    final repository = _RecordingDoorDetailRepository(devices: [_device()])
      ..shouldFailUnbind = true;
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      alreadyAddedDevicesControllerProvider.notifier,
    );

    await controller.loadInitial(doorId: '12');
    await controller.unbindDevice(doorId: '12', deviceId: '1');

    final state = container.read(alreadyAddedDevicesControllerProvider);
    expect(state.devices, hasLength(1));
    expect(state.unbindFailedDeviceId, '1');
    expect(state.pendingUnbindDeviceId, isNull);
  });
}

ProviderContainer _container(_RecordingDoorDetailRepository repository) {
  return ProviderContainer(
    overrides: [doorDetailRepositoryProvider.overrideWithValue(repository)],
  );
}

DoorDevice _device() {
  return const DoorDevice(
    deviceId: 'device-1',
    sn: 'opener_B8F86211A9DC',
    deviceType: 'opener',
    bleName: 'Garage door',
  );
}

class _RecordingDoorDetailRepository implements DoorDetailRepository {
  _RecordingDoorDetailRepository({required this.devices});

  List<DoorDevice> devices;
  bool shouldFail = false;
  bool shouldFailUnbind = false;
  final List<String> requestedDeviceDoorIds = <String>[];
  final List<String> unboundDeviceIds = <String>[];

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) async {
    requestedDeviceDoorIds.add(doorId);
    if (shouldFail) {
      throw StateError('network failure');
    }
    return devices;
  }

  @override
  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) async {
    unboundDeviceIds.add(deviceId);
    if (shouldFailUnbind) {
      throw StateError('unbind failure');
    }
  }
}
