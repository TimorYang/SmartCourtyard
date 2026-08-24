import 'package:flinx/features/add_device/application/device_type_ble_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps DoorDevice.deviceType values to BLE name prefixes', () {
    expect(bleNamePrefixForDoorDeviceType('dongle'), 'Noru_');
    expect(bleNamePrefixForDoorDeviceType('opener'), 'opener_');
    expect(bleNamePrefixForDoorDeviceType('evolution'), 'Evo_');
    expect(bleNamePrefixForDoorDeviceType('fbox'), 'Fbox_');
  });

  test('normalizes device types and defaults invalid values to opener', () {
    expect(normalizeDoorDeviceType(' Evolution '), 'evolution');
    expect(normalizeDoorDeviceType(null), defaultDoorDeviceType);
    expect(normalizeDoorDeviceType('unknown'), defaultDoorDeviceType);
  });

  test('matches BLE names using the selected device type', () {
    expect(bleNameMatchesDoorDeviceType('Noru_123', 'dongle'), isTrue);
    expect(bleNameMatchesDoorDeviceType('opener_123', 'dongle'), isFalse);
  });
}
