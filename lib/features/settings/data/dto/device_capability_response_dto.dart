class DeviceCapabilityResponseDto {
  const DeviceCapabilityResponseDto({
    required this.code,
    required this.label,
    this.unit,
    this.options = const <DeviceCapabilityOptionResponseDto>[],
  });

  factory DeviceCapabilityResponseDto.fromJson(Map<String, dynamic> json) {
    return DeviceCapabilityResponseDto(
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
      unit: json['unit'] as String?,
      options: (json['options'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(DeviceCapabilityOptionResponseDto.fromJson)
          .toList(growable: false),
    );
  }

  final String code;
  final String label;
  final String? unit;
  final List<DeviceCapabilityOptionResponseDto> options;
}

class DeviceCapabilityOptionResponseDto {
  const DeviceCapabilityOptionResponseDto({
    required this.value,
    required this.label,
  });

  factory DeviceCapabilityOptionResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return DeviceCapabilityOptionResponseDto(
      value: (json['value'] as num?)?.toInt() ?? 0,
      label: json['label'] as String? ?? '',
    );
  }

  final int value;
  final String label;
}
