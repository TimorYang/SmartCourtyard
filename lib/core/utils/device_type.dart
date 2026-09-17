abstract final class DeviceTypeValues {
  static const dongle = 'dongle';
  static const opener = 'opener';
  static const evolution = 'evolution';
  static const fBox = 'fbox';
  static const hub = 'hub';
  static const video = 'video';
}

/// Maps the backend's current hub identifier and the legacy F-box identifier
/// to the same internal device behavior.
String canonicalDoorDeviceType(String? deviceType) {
  final normalized = deviceType?.trim().toLowerCase() ?? '';
  return normalized == DeviceTypeValues.hub
      ? DeviceTypeValues.fBox
      : normalized;
}

bool isFBoxDeviceType(String? deviceType) {
  return canonicalDoorDeviceType(deviceType) == DeviceTypeValues.fBox;
}
