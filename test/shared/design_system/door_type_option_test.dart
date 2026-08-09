import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/shared/design_system/door_type_option.dart';
import 'package:flinx/shared/l10n/app_localizations_en.dart';
import 'package:flinx/shared/l10n/app_localizations_zh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every door type to its presentation option and image', () {
    final expectations = {
      DoorType.garage: 'assets/icons/add_device/add_new_doors_garage_door.png',
      DoorType.roller: 'assets/icons/add_device/add_new_doors_roller_door.png',
      DoorType.industrial:
          'assets/icons/add_device/add_new_doors_industrial_door.png',
      DoorType.swing: 'assets/icons/add_device/add_new_doors_swing_gate.png',
      DoorType.sliding:
          'assets/icons/add_device/add_new_doors_sliding_gate.png',
    };

    expect(DoorTypeOption.values, hasLength(DoorType.values.length));
    expectations.forEach((doorType, assetPath) {
      final option = DoorTypeOption.fromDoorType(doorType);

      expect(option.doorType, doorType);
      expect(option.assetPath, assetPath);
    });
    expect(DoorType.values.map((doorType) => doorType.wireValue), [
      0,
      1,
      2,
      3,
      4,
    ]);
  });

  test('returns localized names for each door type', () {
    expect(
      DoorTypeOption.garage.localizedName(AppLocalizationsEn()),
      'Garage door',
    );
    expect(DoorTypeOption.garage.localizedName(AppLocalizationsZh()), '车库门');
  });

  test('unknown wire values fall back to the garage option', () {
    final doorType = DoorType.fromWireValue(99);

    expect(doorType, DoorType.garage);
    expect(DoorTypeOption.fromDoorType(doorType), DoorTypeOption.garage);
  });
}
