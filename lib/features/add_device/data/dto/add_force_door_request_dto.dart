class AddForceDoorRequestDto {
  const AddForceDoorRequestDto({
    required this.sn,
    this.doorId,
    this.sceneId,
    required this.doorType,
  });

  final String sn;
  final String? doorId;
  final int? sceneId;
  final int doorType;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sn': sn,
      if (doorId != null) 'doorId': doorId,
      if (sceneId != null) 'sceneId': sceneId,
      if (doorId == null) 'doorType': doorType,
    };
  }
}
