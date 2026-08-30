enum DoorControlMode {
  osc,
  pb;

  static DoorControlMode fromBackend({int? value, String? label}) {
    final normalizedLabel = label
        ?.trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (normalizedLabel?.contains('PB') == true) {
      return DoorControlMode.pb;
    }
    if (normalizedLabel?.contains('OSC') == true ||
        normalizedLabel?.contains('OPENSTOPCLOSE') == true) {
      return DoorControlMode.osc;
    }

    return value == 2 ? DoorControlMode.pb : DoorControlMode.osc;
  }
}
