class AddForceDoorRequestDto {
  const AddForceDoorRequestDto({required this.sn, this.doorId});

  final String sn;
  final String? doorId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'sn': sn, if (doorId != null) 'doorId': doorId};
  }
}
