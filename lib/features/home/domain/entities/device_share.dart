/// Device-share permission level selected in the Permissions field.
enum DeviceSharePermission {
  administrator,
  guest;

  String get jsonValue => name;

  static DeviceSharePermission fromJson(Object? value) {
    return DeviceSharePermission.values.firstWhere(
      (permission) => permission.jsonValue == value,
      orElse: () => DeviceSharePermission.guest,
    );
  }
}

/// Expiration option selected in the Access end field.
enum DeviceShareAccessEndMode {
  neverExpired,
  twoHours,
  customize;

  String get jsonValue => name;

  static DeviceShareAccessEndMode fromJson(Object? value) {
    return DeviceShareAccessEndMode.values.firstWhere(
      (mode) => mode.jsonValue == value,
      orElse: () => DeviceShareAccessEndMode.neverExpired,
    );
  }
}

/// A controllable capability shown in the Capabilities list.
enum DeviceShareCapability {
  doorControl,
  partialOpen,
  ledDelay,
  autoClose,
  doorOpenReminder,
  doorOpenForce,
  doorOpenSpeed;

  String get jsonValue => name;

  static DeviceShareCapability fromJson(Object? value) {
    return DeviceShareCapability.values.firstWhere(
      (capability) => capability.jsonValue == value,
      orElse: () => DeviceShareCapability.doorControl,
    );
  }
}

/// The access end value displayed in the Time row.
class DeviceShareAccessEnd {
  const DeviceShareAccessEnd({required this.mode, this.expiresAt});

  /// Access-end option from the UI dropdown; required; example: `customize`.
  final DeviceShareAccessEndMode mode;

  /// Time-row value in UTC; nullable for Never expired and an unfinished
  /// Customize selection; example: `2026-07-24T12:00:00.000Z`.
  final DateTime? expiresAt;

  factory DeviceShareAccessEnd.fromJson(Map<String, dynamic> json) {
    final expiresAtRaw = json['expiresAt'] as String?;
    return DeviceShareAccessEnd(
      mode: DeviceShareAccessEndMode.fromJson(json['mode']),
      expiresAt: expiresAtRaw == null ? null : DateTime.parse(expiresAtRaw),
    );
  }

  factory DeviceShareAccessEnd.mock() {
    return DeviceShareAccessEnd(
      mode: DeviceShareAccessEndMode.customize,
      expiresAt: DateTime.utc(2026, 7, 24, 12),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.jsonValue,
      'expiresAt': expiresAt?.toUtc().toIso8601String(),
    };
  }
}

/// Complete data model for the DeviceSharePage sharing form.
class DeviceShareDraft {
  const DeviceShareDraft({
    required this.deviceId,
    required this.address,
    required this.permission,
    required this.accessEnd,
    required this.selectedCapabilities,
  });

  /// Shared target device identifier; required by the share operation; example:
  /// `door-001`.
  final String deviceId;

  /// Address input in the UI, validated as an email before confirmation;
  /// required; example: `alex@example.com`.
  final String address;

  /// Permissions dropdown selection; required; example: `administrator`.
  final DeviceSharePermission permission;

  /// Access end dropdown and Time-row state; required; example: a two-hour
  /// expiry.
  final DeviceShareAccessEnd accessEnd;

  /// Selected capability identifiers; required; derived from the front-end's
  /// static Capabilities list; example: `[doorControl, partialOpen]`.
  final List<DeviceShareCapability> selectedCapabilities;

  factory DeviceShareDraft.fromJson(Map<String, dynamic> json) {
    return DeviceShareDraft(
      deviceId: json['deviceId'] as String? ?? '',
      address: json['address'] as String? ?? '',
      permission: DeviceSharePermission.fromJson(json['permission']),
      accessEnd: DeviceShareAccessEnd.fromJson(
        Map<String, dynamic>.from(json['accessEnd'] as Map? ?? const {}),
      ),
      selectedCapabilities:
          (json['selectedCapabilities'] as List<dynamic>? ?? const [])
              .map(DeviceShareCapability.fromJson)
              .toList(growable: false),
    );
  }

  factory DeviceShareDraft.mock() {
    return DeviceShareDraft(
      deviceId: 'door-001',
      address: 'alex@example.com',
      permission: DeviceSharePermission.administrator,
      accessEnd: DeviceShareAccessEnd.mock(),
      selectedCapabilities: DeviceShareCapability.values,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'address': address,
      'permission': permission.jsonValue,
      'accessEnd': accessEnd.toJson(),
      'selectedCapabilities': selectedCapabilities
          .map((capability) => capability.jsonValue)
          .toList(),
    };
  }
}
