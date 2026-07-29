import 'package:flutter/material.dart';

import '../../platform_bridge/hardware_models.dart';
import '../l10n/app_localizations.dart';

/// Presentation metadata for a supported [DoorType].
enum DoorTypeOption {
  garage(
    doorType: DoorType.garage,
    assetPath: 'assets/icons/add_device/add_new_doors_garage_door.png',
    fallbackIcon: Icons.garage_outlined,
  ),
  roller(
    doorType: DoorType.roller,
    assetPath: 'assets/icons/add_device/add_new_doors_roller_door.png',
    fallbackIcon: Icons.window_outlined,
  ),
  industrial(
    doorType: DoorType.industrial,
    assetPath: 'assets/icons/add_device/add_new_doors_industrial_door.png',
    fallbackIcon: Icons.warehouse_outlined,
  ),
  swing(
    doorType: DoorType.swing,
    assetPath: 'assets/icons/add_device/add_new_doors_swing_gate.png',
    fallbackIcon: Icons.door_front_door_outlined,
  ),
  sliding(
    doorType: DoorType.sliding,
    assetPath: 'assets/icons/add_device/add_new_doors_sliding_gate.png',
    fallbackIcon: Icons.door_sliding_outlined,
  );

  const DoorTypeOption({
    required this.doorType,
    required this.assetPath,
    required this.fallbackIcon,
  });

  final DoorType doorType;
  final String assetPath;
  final IconData fallbackIcon;

  static DoorTypeOption fromDoorType(DoorType doorType) {
    return switch (doorType) {
      DoorType.garage => DoorTypeOption.garage,
      DoorType.roller => DoorTypeOption.roller,
      DoorType.industrial => DoorTypeOption.industrial,
      DoorType.swing => DoorTypeOption.swing,
      DoorType.sliding => DoorTypeOption.sliding,
    };
  }

  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      DoorTypeOption.garage => l10n.addNewDoorsGarageDoor,
      DoorTypeOption.roller => l10n.addNewDoorsRollerDoor,
      DoorTypeOption.industrial => l10n.addNewDoorsIndustrialDoor,
      DoorTypeOption.swing => l10n.addNewDoorsSwingGate,
      DoorTypeOption.sliding => l10n.addNewDoorsSlidingGate,
    };
  }
}
