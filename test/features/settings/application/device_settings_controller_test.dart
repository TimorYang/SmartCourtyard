import 'package:flinx/features/settings/application/device_settings_controller.dart';
import 'package:flinx/features/settings/application/providers.dart';
import 'package:flinx/features/settings/domain/entities/device_setting.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads settings and refreshes after a successful write', () async {
    final container = ProviderContainer(
      overrides: [
        deviceSettingsHardwareGatewayProvider.overrideWithValue(
          MockHardwareGateway(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = deviceSettingsControllerProvider('device-1');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    await _waitUntil(() => !container.read(provider).loading);
    expect(
      container.read(provider).values[DeviceSettingKey.ledOffDelay]?.rawValue,
      30,
    );

    final didWrite = await container
        .read(provider.notifier)
        .setRawValue(DeviceSettingKey.ledOffDelay, 0x20);

    expect(didWrite, isTrue);
    expect(container.read(provider).pendingKey, isNull);
    expect(
      container.read(provider).values[DeviceSettingKey.ledOffDelay]?.rawValue,
      0x20,
    );
  });

  test('rejects duplicate writes while a setting is pending', () async {
    final gateway = MockHardwareGateway();
    final container = ProviderContainer(
      overrides: [
        deviceSettingsHardwareGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);
    final provider = deviceSettingsControllerProvider('device-1');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await _waitUntil(() => !container.read(provider).loading);

    final first = container
        .read(provider.notifier)
        .setRawValue(DeviceSettingKey.partialOpen, 8);
    final second = await container
        .read(provider.notifier)
        .setRawValue(DeviceSettingKey.openingForce, 6);

    expect(second, isFalse);
    expect(await first, isTrue);
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100 && !condition(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(condition(), isTrue);
}
