class AddForceDoorRequestDto {
  const AddForceDoorRequestDto({required this.sn});

  final String sn;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'sn': sn};
  }
}
