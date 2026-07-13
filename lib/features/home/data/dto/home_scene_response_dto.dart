class HomeSceneResponseDto {
  const HomeSceneResponseDto({
    required this.defaultScene,
    required this.doorCount,
    required this.id,
    required this.name,
  });

  final bool defaultScene;
  final int doorCount;
  final int id;
  final String name;

  factory HomeSceneResponseDto.fromJson(Map<String, dynamic> json) {
    return HomeSceneResponseDto(
      defaultScene: json['defaultScene'] as bool? ?? false,
      doorCount: _parseInt(json['doorCount']),
      id: _parseInt(json['id']),
      name: json['name'] as String? ?? '',
    );
  }

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
