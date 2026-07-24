class MoveHomeDoorSceneRequestDto {
  const MoveHomeDoorSceneRequestDto({required this.sceneId});

  final int sceneId;

  factory MoveHomeDoorSceneRequestDto.fromJson(Map<String, dynamic> json) {
    final value = json['sceneId'];
    return MoveHomeDoorSceneRequestDto(
      sceneId: value is num ? value.toInt() : int.tryParse('$value') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'sceneId': sceneId};
}
