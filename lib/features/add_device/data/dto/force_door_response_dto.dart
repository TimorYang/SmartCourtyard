class ForceDoorResponseDto {
  const ForceDoorResponseDto({
    required this.id,
    required this.hardwareSn,
    this.name,
  });

  final int id;
  final String hardwareSn;
  final String? name;

  factory ForceDoorResponseDto.fromJson(Map<String, dynamic> json) {
    return ForceDoorResponseDto(
      id: _parseInt(json['id']),
      hardwareSn: json['hardwareSn'] as String? ?? '',
      name: json['name'] as String?,
    );
  }

  bool get isValid => id > 0 && hardwareSn.trim().isNotEmpty;

  static int _parseInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
