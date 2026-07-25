/// A device that currently has an authenticated account session.
class ManagedLoginDevice {
  const ManagedLoginDevice({
    required this.id,
    required this.type,
    required this.loggedInAt,
    required this.isCurrentDevice,
  });

  /// Stable identifier used to target this row for future edit or sign-out actions.
  final String id;

  /// Device category used to choose the card's device illustration.
  final ManagedLoginDeviceType type;

  /// Timestamp shown under the device name to indicate when it logged in.
  final DateTime loggedInAt;

  /// Whether this row represents the device currently using the application.
  final bool isCurrentDevice;
}

/// The visual device categories supported by the Manage devices page.
enum ManagedLoginDeviceType { phone, tablet }
