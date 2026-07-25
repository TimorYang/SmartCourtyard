class DeviceCapability {
  const DeviceCapability({
    required this.code,
    required this.label,
    this.unit,
    this.options = const <DeviceCapabilityOption>[],
  });

  final String code;
  final String label;
  final String? unit;
  final List<DeviceCapabilityOption> options;
}

class DeviceCapabilityOption {
  const DeviceCapabilityOption({required this.value, required this.label});

  final int value;
  final String label;
}

abstract final class DeviceCapabilityCode {
  static const doorControl = 'DOOR_CONTROL';
  static const partialOpen = 'PARTIAL_OPEN';
  static const partialOpenLevel = 'PARTIAL_OPEN_LEVEL';
  static const ledControl = 'LED_CONTROL';
  static const ledOffDelay = 'LED_OFF_DELAY';
  static const autoClose = 'AUTO_CLOSE';
  static const transmitterPairing = 'TRANSMITTER_PAIRING';
  static const forceMargin = 'FORCE_MARGIN';
  static const doorOpenReminder = 'DOOR_OPEN_REMINDER';
  static const openingSpeed = 'OPENING_SPEED';
}
