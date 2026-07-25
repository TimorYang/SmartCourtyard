import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/managed_login_device.dart';

final managedDevicesControllerProvider =
    NotifierProvider<ManagedDevicesController, List<ManagedLoginDevice>>(
      ManagedDevicesController.new,
    );

/// Owns the temporary, in-memory device sessions shown by Manage devices.
///
/// This controller intentionally remains local-only until the signed-in device
/// management API is available.
class ManagedDevicesController extends Notifier<List<ManagedLoginDevice>> {
  static final _initialDevices = <ManagedLoginDevice>[
    ManagedLoginDevice(
      id: 'iphone-16-pro-max',
      type: ManagedLoginDeviceType.phone,
      loggedInAt: _iphoneLoggedInAt,
      isCurrentDevice: true,
    ),
    ManagedLoginDevice(
      id: 'ipad-air',
      type: ManagedLoginDeviceType.tablet,
      loggedInAt: _ipadLoggedInAt,
      isCurrentDevice: false,
    ),
  ];

  static final _iphoneLoggedInAt = DateTime(2025, 8, 2, 11, 2);
  static final _ipadLoggedInAt = DateTime(2025, 8, 2, 11, 2);

  @override
  List<ManagedLoginDevice> build() => _initialDevices;

  void removeDevice(String deviceId) {
    if (!state.any((device) => device.id == deviceId)) {
      return;
    }
    state = state
        .where((device) => device.id != deviceId)
        .toList(growable: false);
  }
}
