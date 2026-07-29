class UpdateHomeDoorCoverRequestDto {
  const UpdateHomeDoorCoverRequestDto({required this.coverFileId});

  final int coverFileId;

  Map<String, dynamic> toJson() => {'coverFileId': coverFileId};
}
