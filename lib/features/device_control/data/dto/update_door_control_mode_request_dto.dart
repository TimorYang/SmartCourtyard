class UpdateDoorControlModeRequestDto {
  const UpdateDoorControlModeRequestDto({
    required this.sn,
    required this.controlMode,
  });

  final String sn;
  final String controlMode;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'sn': sn,
    'controlMode': controlMode,
  };
}
