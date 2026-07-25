import 'package:flinx/features/account/application/managed_devices_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removes only an existing managed device', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(managedDevicesControllerProvider), hasLength(2));

    container
        .read(managedDevicesControllerProvider.notifier)
        .removeDevice('ipad-air');

    expect(
      container
          .read(managedDevicesControllerProvider)
          .map((device) => device.id),
      ['iphone-16-pro-max'],
    );
  });

  test('ignores removal requests for an unknown managed device', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final initialDevices = container.read(managedDevicesControllerProvider);

    container
        .read(managedDevicesControllerProvider.notifier)
        .removeDevice('unknown-device');

    expect(
      container.read(managedDevicesControllerProvider),
      same(initialDevices),
    );
  });
}
