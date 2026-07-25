class DoorSettingSnapshot {
  const DoorSettingSnapshot({
    required this.code,
    required this.label,
    required this.supported,
    required this.configured,
    this.currentValue,
    this.unit,
  });

  final String code;
  final String label;
  final bool supported;
  final bool configured;
  final int? currentValue;
  final String? unit;
}
