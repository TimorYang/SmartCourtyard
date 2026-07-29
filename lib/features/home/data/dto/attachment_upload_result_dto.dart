class AttachmentUploadResultDto {
  const AttachmentUploadResultDto({required this.fileId});

  final int fileId;

  factory AttachmentUploadResultDto.fromJson(Map<String, dynamic> json) {
    final rawFileId = json['fileId'];
    return AttachmentUploadResultDto(
      fileId: rawFileId is num ? rawFileId.toInt() : int.tryParse('$rawFileId') ?? 0,
    );
  }
}
