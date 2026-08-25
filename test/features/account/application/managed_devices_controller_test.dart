import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/managed_login_device.dart';
import 'package:flinx/features/account/domain/repositories/managed_devices_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removes only an existing managed device', () async {
    final repository = _FakeManagedDevicesRepository();
    final container = ProviderContainer(
      overrides: [
        managedDevicesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(managedDevicesControllerProvider.notifier).refresh();

    await container
        .read(managedDevicesControllerProvider.notifier)
        .removeDevice('ipad-air');

    expect(
      container
          .read(managedDevicesControllerProvider)
          .requireValue
          .map((device) => device.sessionId),
      ['iphone-16-pro-max'],
    );
  });

  test('ignores removal requests for an unknown managed device', () async {
    final repository = _FakeManagedDevicesRepository();
    final container = ProviderContainer(
      overrides: [
        managedDevicesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(managedDevicesControllerProvider.notifier).refresh();
    final initialDevices = container
        .read(managedDevicesControllerProvider)
        .requireValue;

    await container
        .read(managedDevicesControllerProvider.notifier)
        .removeDevice('unknown-device');

    expect(
      container.read(managedDevicesControllerProvider).requireValue,
      same(initialDevices),
    );
  });
}

class _FakeManagedDevicesRepository implements ManagedDevicesRepository {
  final devices = [
    const ManagedLoginDevice(
      sessionId: 'ipad-air',
      deviceModel: 'iPad Air',
      platform: ManagedLoginDevicePlatform.ios,
      lastLoginTime: null,
      currentDevice: false,
    ),
    const ManagedLoginDevice(
      sessionId: 'iphone-16-pro-max',
      deviceModel: 'iPhone 16 Pro Max',
      platform: ManagedLoginDevicePlatform.ios,
      lastLoginTime: null,
      currentDevice: true,
    ),
  ];

  @override
  Future<List<ManagedLoginDevice>> fetchLoginDevices({
    required String requestId,
  }) async => devices;

  @override
  Future<void> removeLoginDevice({
    required String sessionId,
    required String requestId,
  }) async {}
}
