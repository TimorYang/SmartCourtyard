import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/shared/design_system/door_type_visuals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps door type wire values to their local door visuals', () {
    final expectations = {
      0: 'assets/icons/add_device/add_new_doors_garage_door.png',
      1: 'assets/icons/add_device/add_new_doors_roller_door.png',
      2: 'assets/icons/add_device/add_new_doors_industrial_door.png',
      3: 'assets/icons/add_device/add_new_doors_swing_gate.png',
      4: 'assets/icons/add_device/add_new_doors_sliding_gate.png',
    };

    expectations.forEach((wireValue, assetPath) {
      final type = DoorType.fromWireValue(wireValue);

      expect(type.wireValue, wireValue);
      expect(DoorTypeVisuals.forType(type).assetPath, assetPath);
    });
  });

  test('falls back to garage for an unknown door type', () {
    expect(DoorType.fromWireValue(99), DoorType.garage);
  });
}
