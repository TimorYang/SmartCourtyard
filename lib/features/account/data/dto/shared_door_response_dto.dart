class SharedDoorResponseDto {
  const SharedDoorResponseDto({
    required this.doorId,
    required this.name,
    required this.coverFileId,
    this.doorType,
    required this.sharedUserCount,
  });

  final int doorId;
  final String name;

  final int? coverFileId;
  final int? doorType;
  final int sharedUserCount;

  factory SharedDoorResponseDto.fromJson(Map<String, dynamic> json) {
    final doorId = _parseInt(json['doorId']);
    if (doorId == null) {
      throw const FormatException('Shared door response is missing doorId.');
    }
    return SharedDoorResponseDto(
      doorId: doorId,
      name: json['name'] as String? ?? '',
      coverFileId: _parseInt(json['coverFileId']),
      doorType: _parseInt(json['doorType']),
      sharedUserCount: _parseInt(json['sharedUserCount']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'doorId': doorId,
    'name': name,
    'coverFileId': coverFileId,
    'doorType': doorType,
    'sharedUserCount': sharedUserCount,
  };

  static int? _parseInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
