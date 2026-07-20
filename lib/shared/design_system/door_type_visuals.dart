import 'package:flutter/material.dart';

import '../../platform_bridge/hardware_models.dart';

class DoorTypeVisuals {
  const DoorTypeVisuals._();

  static DoorTypeVisual forType(DoorType doorType) {
    return switch (doorType) {
      DoorType.garage => const DoorTypeVisual(
        assetPath: 'assets/icons/add_device/add_new_doors_garage_door.png',
        fallbackIcon: Icons.garage_outlined,
      ),
      DoorType.roller => const DoorTypeVisual(
        assetPath: 'assets/icons/add_device/add_new_doors_roller_door.png',
        fallbackIcon: Icons.window_outlined,
      ),
      DoorType.industrial => const DoorTypeVisual(
        assetPath: 'assets/icons/add_device/add_new_doors_industrial_door.png',
        fallbackIcon: Icons.warehouse_outlined,
      ),
      DoorType.swing => const DoorTypeVisual(
        assetPath: 'assets/icons/add_device/add_new_doors_swing_gate.png',
        fallbackIcon: Icons.door_front_door_outlined,
      ),
      DoorType.sliding => const DoorTypeVisual(
        assetPath: 'assets/icons/add_device/add_new_doors_sliding_gate.png',
        fallbackIcon: Icons.door_sliding_outlined,
      ),
    };
  }
}

class DoorTypeVisual {
  const DoorTypeVisual({required this.assetPath, required this.fallbackIcon});

  final String assetPath;
  final IconData fallbackIcon;
}
