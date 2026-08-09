class AddForceDoorRequestDto {
  const AddForceDoorRequestDto({
    required this.sn,
    this.doorId,
    required this.doorType,
  });

  final String sn;
  final String? doorId;
  final int doorType;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sn': sn,
      if (doorId != null) 'doorId': doorId,
      if (doorId == null) 'doorType': doorType,
    };
  }
}
