enum DoorControlMode {
  pb,
  osc,
  unset;

  static DoorControlMode fromBackend({int? value}) {
    return switch (value) {
      0 => DoorControlMode.pb,
      1 => DoorControlMode.osc,
      2 => DoorControlMode.unset,
      _ => DoorControlMode.unset,
    };
  }

  int get backendValue {
    return switch (this) {
      DoorControlMode.pb => 0,
      DoorControlMode.osc => 1,
      DoorControlMode.unset => 2,
    };
  }
}
