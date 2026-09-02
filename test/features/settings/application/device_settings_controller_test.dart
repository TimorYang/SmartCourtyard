import 'dart:typed_data';

import 'package:flinx/features/settings/application/device_settings_controller.dart';
import 'package:flinx/features/settings/application/providers.dart';
import 'package:flinx/features/settings/domain/entities/device_setting.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches reported setting candidates in source priority order', () {
    const value = DeviceSettingValue(
      key: DeviceSettingKey.autoCloseTime,
      rawValue: 3,
      candidateValues: <int>[3, 75],
    );

    expect(matchingDeviceSettingCandidate(value, <int>[3, 75]), 3);
    expect(matchingDeviceSettingCandidate(value, <int>[75]), 75);
    expect(matchingDeviceSettingCandidate(value, <int>[15, 30]), isNull);
  });

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
      5,
    );

    final didWrite = await container
        .read(provider.notifier)
        .setRawValue(DeviceSettingKey.ledOffDelay, 0x09);

    expect(didWrite, isTrue);
    expect(container.read(provider).pendingKey, isNull);
    expect(
      container.read(provider).values[DeviceSettingKey.ledOffDelay]?.rawValue,
      0x09,
    );
  });

  test('writes 0x2712 and matches readback against allowed options', () async {
    final gateway = MockHardwareGateway(
      autoCloseAttributeId: 0x2725,
      autoCloseValue: 75,
    );
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

    final initialValue = container
        .read(provider)
        .values[DeviceSettingKey.autoCloseTime];
    expect(initialValue?.rawValue, 75);
    expect(initialValue?.candidateValues, <int>[75]);

    final controller = container.read(provider.notifier);
    expect(
      await controller.setRawValue(
        DeviceSettingKey.autoCloseTime,
        90,
        allowedValues: const <int>[15, 75, 90],
      ),
      isTrue,
    );
    var snapshot = await gateway.queryDeviceAttributes(
      requestId: 'verify-controller-2725',
      deviceId: 'device-1',
    );
    expect(
      snapshot.attributes
          .singleWhere((attribute) => attribute.id == 0x2712)
          .value,
      Uint8List.fromList(<int>[0x5A]),
    );
    expect(
      snapshot.attributes
          .singleWhere((attribute) => attribute.id == 0x2725)
          .value,
      Uint8List.fromList(<int>[0x00, 0x4B]),
    );
    expect(
      container.read(provider).values[DeviceSettingKey.autoCloseTime]?.rawValue,
      90,
    );

    expect(
      await controller.setEnabled(
        DeviceSettingKey.autoCloseTime,
        enabled: false,
        allowedValues: const <int>[15, 75, 90],
      ),
      isTrue,
    );
    snapshot = await gateway.queryDeviceAttributes(
      requestId: 'verify-controller-2725-disabled',
      deviceId: 'device-1',
    );
    expect(
      snapshot.attributes
          .singleWhere((attribute) => attribute.id == 0x2712)
          .value,
      Uint8List.fromList(<int>[0x00]),
    );
  });

  test(
    'replaces values when the latest attribute snapshot omits auto-close',
    () async {
      final gateway = _RecordingHardwareGateway();
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
      expect(
        container.read(provider).values,
        contains(DeviceSettingKey.autoCloseTime),
      );

      gateway.emitDeviceAttributeSnapshot(
        DeviceAttributeSnapshot(
          deviceId: 'device-1',
          sequence: 2,
          timestampMillis: 2,
          origin: DeviceAttributeReportOrigin.activeReport,
          attributes: [
            DeviceAttribute(
              id: DeviceSettingKey.ledOffDelay.attributeId!,
              value: Uint8List.fromList(<int>[0x06]),
            ),
          ],
        ),
      );
      await _waitUntil(
        () => !container
            .read(provider)
            .values
            .containsKey(DeviceSettingKey.autoCloseTime),
      );

      expect(
        container.read(provider).values.keys,
        contains(DeviceSettingKey.ledOffDelay),
      );
      expect(
        container.read(provider).values,
        isNot(contains(DeviceSettingKey.autoCloseTime)),
      );
      expect(
        await container
            .read(provider.notifier)
            .setRawValue(
              DeviceSettingKey.autoCloseTime,
              15,
              allowedValues: const <int>[15, 30],
            ),
        isTrue,
      );
      expect(gateway.attributeWriteCount, 1);
    },
  );

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

  test('enables auto-close with an explicit capability option', () async {
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

    expect(
      await container
          .read(provider.notifier)
          .setEnabled(
            DeviceSettingKey.autoCloseTime,
            enabled: true,
            enabledValue: 15,
            allowedValues: const <int>[15, 30],
          ),
      isTrue,
    );
    expect(
      container.read(provider).values[DeviceSettingKey.autoCloseTime]?.rawValue,
      15,
    );
    expect(
      await container
          .read(provider.notifier)
          .setEnabled(DeviceSettingKey.doorOpenReminder, enabled: true),
      isTrue,
    );
    expect(gateway.doorOpenReminderValues, <int>[10]);
    expect(
      container.read(provider).values,
      isNot(contains(DeviceSettingKey.doorOpenReminder)),
    );
  });

  test('keeps the selected option when BLE readback does not match', () async {
    final gateway = _IgnoringAutoCloseWriteHardwareGateway();
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

    final saved = await container
        .read(provider.notifier)
        .setRawValue(
          DeviceSettingKey.autoCloseTime,
          15,
          allowedValues: const <int>[15, 30],
        );

    expect(saved, isTrue);
    expect(
      container.read(provider).values[DeviceSettingKey.autoCloseTime]?.rawValue,
      15,
    );
  });

  test('keeps the selected option when BLE readback fails', () async {
    final gateway = _FailingAutoCloseReadbackHardwareGateway();
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

    final saved = await container
        .read(provider.notifier)
        .setRawValue(
          DeviceSettingKey.autoCloseTime,
          30,
          allowedValues: const <int>[15, 30],
        );

    expect(saved, isTrue);
    expect(
      container.read(provider).values[DeviceSettingKey.autoCloseTime]?.rawValue,
      30,
    );
    expect(container.read(provider).pendingKey, isNull);
  });

  test('preserves a newer attribute snapshot when the write fails', () async {
    final gateway = _SnapshotThenFailingWriteHardwareGateway();
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
    expect(
      container.read(provider).values[DeviceSettingKey.ledOffDelay]?.rawValue,
      5,
    );

    final saved = await container
        .read(provider.notifier)
        .setRawValue(DeviceSettingKey.openingForce, 4);

    expect(saved, isFalse);
    expect(
      container.read(provider).values[DeviceSettingKey.ledOffDelay]?.rawValue,
      6,
    );
    expect(container.read(provider).pendingKey, isNull);
  });

  test(
    'applies later 0x2725 reports without retaining write options',
    () async {
      final gateway = MockHardwareGateway(
        autoCloseAttributeId: 0x2725,
        autoCloseValue: 75,
      );
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

      expect(
        await container
            .read(provider.notifier)
            .setRawValue(
              DeviceSettingKey.autoCloseTime,
              30,
              allowedValues: const <int>[15, 30],
            ),
        isTrue,
      );
      expect(
        container
            .read(provider)
            .values[DeviceSettingKey.autoCloseTime]
            ?.rawValue,
        30,
      );

      gateway.emitDeviceAttributeSnapshot(
        DeviceAttributeSnapshot(
          deviceId: 'device-1',
          sequence: 3,
          timestampMillis: 3,
          origin: DeviceAttributeReportOrigin.activeReport,
          attributes: [
            DeviceAttribute(
              id: 0x2725,
              value: Uint8List.fromList(<int>[0x00, 0x4B]),
            ),
          ],
        ),
      );
      await _waitUntil(
        () =>
            container
                .read(provider)
                .values[DeviceSettingKey.autoCloseTime]
                ?.rawValue ==
            75,
      );

      expect(
        container
            .read(provider)
            .values[DeviceSettingKey.autoCloseTime]
            ?.rawValue,
        75,
      );
      expect(
        container
            .read(provider)
            .values[DeviceSettingKey.autoCloseTime]
            ?.candidateValues,
        <int>[75],
      );
    },
  );

  test('uses cmd 0x0E09 for door reminder enable and disable', () async {
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
    final controller = container.read(provider.notifier);

    expect(
      await controller.setEnabled(
        DeviceSettingKey.doorOpenReminder,
        enabled: true,
      ),
      isTrue,
    );
    expect(
      await controller.setEnabled(
        DeviceSettingKey.doorOpenReminder,
        enabled: false,
      ),
      isTrue,
    );
    expect(gateway.doorOpenReminderValues, <int>[10, 0]);
    expect(
      container.read(provider).values,
      isNot(contains(DeviceSettingKey.doorOpenReminder)),
    );
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100 && !condition(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(condition(), isTrue);
}

class _RecordingHardwareGateway extends MockHardwareGateway {
  int attributeWriteCount = 0;

  @override
  Future<DeviceAttributeWriteResult> setDeviceAttributes({
    required String requestId,
    required String deviceId,
    required List<DeviceAttribute> attributes,
  }) async {
    attributeWriteCount += 1;
    return super.setDeviceAttributes(
      requestId: requestId,
      deviceId: deviceId,
      attributes: attributes,
    );
  }
}

class _IgnoringAutoCloseWriteHardwareGateway extends MockHardwareGateway {
  _IgnoringAutoCloseWriteHardwareGateway() : super(autoCloseValue: 99);

  @override
  Future<DeviceAttributeWriteResult> setDeviceAttributes({
    required String requestId,
    required String deviceId,
    required List<DeviceAttribute> attributes,
  }) async {
    return DeviceAttributeWriteResult(
      requestId: requestId,
      deviceId: deviceId,
      success: true,
      sequence: 2,
    );
  }
}

class _FailingAutoCloseReadbackHardwareGateway extends MockHardwareGateway {
  var _queryCount = 0;

  @override
  Future<DeviceAttributeSnapshot> queryDeviceAttributes({
    required String requestId,
    required String deviceId,
  }) {
    _queryCount += 1;
    if (_queryCount > 1) {
      throw StateError('readback unavailable');
    }
    return super.queryDeviceAttributes(
      requestId: requestId,
      deviceId: deviceId,
    );
  }
}

class _SnapshotThenFailingWriteHardwareGateway extends MockHardwareGateway {
  @override
  Future<DeviceAttributeWriteResult> setDeviceAttributes({
    required String requestId,
    required String deviceId,
    required List<DeviceAttribute> attributes,
  }) async {
    emitDeviceAttributeSnapshot(
      DeviceAttributeSnapshot(
        requestId: requestId,
        deviceId: deviceId,
        sequence: 2,
        timestampMillis: 2,
        origin: DeviceAttributeReportOrigin.activeReport,
        attributes: [
          DeviceAttribute(
            id: DeviceSettingKey.ledOffDelay.attributeId!,
            value: Uint8List.fromList(<int>[0x06]),
          ),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    throw StateError('attribute write failed');
  }
}
