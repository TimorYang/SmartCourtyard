class DoorSettingResponseDto {
  const DoorSettingResponseDto({
    required this.code,
    required this.label,
    required this.supported,
    required this.configured,
    this.currentValue,
    this.unit,
  });

  factory DoorSettingResponseDto.fromJson(Map<String, dynamic> json) {
    return DoorSettingResponseDto(
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
      supported: json['supported'] as bool? ?? false,
      configured: json['configured'] as bool? ?? false,
      currentValue: (json['currentValue'] as num?)?.toInt(),
      unit: json['unit'] as String?,
    );
  }

  final String code;
  final String label;
  final bool supported;
  final bool configured;
  final int? currentValue;
  final String? unit;
}
