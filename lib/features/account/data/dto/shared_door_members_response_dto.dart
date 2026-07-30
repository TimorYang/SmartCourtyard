class SharedDoorMembersResponseDto {
  const SharedDoorMembersResponseDto({
    required this.doorId,
    required this.doorName,
    required this.administrators,
    required this.guests,
  });
  final int doorId;
  final String doorName;
  final List<SharedDoorMemberResponseDto> administrators;
  final List<SharedDoorMemberResponseDto> guests;
  factory SharedDoorMembersResponseDto.fromJson(Map<String, dynamic> json) =>
      SharedDoorMembersResponseDto(
        doorId: _int(json['doorId']) ?? 0,
        doorName: json['doorName'] as String? ?? '',
        administrators: _members(json['administrators']),
        guests: _members(json['guests']),
      );
  Map<String, dynamic> toJson() => {
    'doorId': doorId,
    'doorName': doorName,
    'administrators': administrators.map((e) => e.toJson()).toList(),
    'guests': guests.map((e) => e.toJson()).toList(),
  };
  static List<SharedDoorMemberResponseDto> _members(Object? value) =>
      (value as List<Object?>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SharedDoorMemberResponseDto.fromJson)
          .toList(growable: false);
  static int? _int(Object? value) => value is num
      ? value.toInt()
      : value is String
      ? int.tryParse(value)
      : null;
}

class SharedDoorMemberResponseDto {
  const SharedDoorMemberResponseDto({
    required this.shareId,
    required this.receiverEmail,
    required this.role,
    required this.expiryType,
    required this.capabilities,
    this.expiresAt,
    this.receiverAvatarCode,
    this.receiverAvatarFileId,
  });
  final int shareId;
  final String receiverEmail;
  final String role;
  final String expiryType;
  final int? expiresAt;
  final String? receiverAvatarCode;
  final int? receiverAvatarFileId;
  final List<String> capabilities;
  factory SharedDoorMemberResponseDto.fromJson(Map<String, dynamic> json) =>
      SharedDoorMemberResponseDto(
        shareId: SharedDoorMembersResponseDto._int(json['shareId']) ?? 0,
        receiverEmail: json['receiverEmail'] as String? ?? '',
        role: json['role']?.toString() ?? '',
        expiryType: json['expiryType']?.toString() ?? '',
        expiresAt: SharedDoorMembersResponseDto._int(json['expiresAt']),
        receiverAvatarCode: json['receiverAvatarCode'] as String?,
        receiverAvatarFileId: SharedDoorMembersResponseDto._int(
          json['receiverAvatarFileId'],
        ),
        capabilities: (json['capabilities'] as List<Object?>? ?? const [])
            .whereType<String>()
            .toList(growable: false),
      );
  Map<String, dynamic> toJson() => {
    'shareId': shareId,
    'receiverEmail': receiverEmail,
    'role': role,
    'expiryType': expiryType,
    'expiresAt': expiresAt,
    'receiverAvatarCode': receiverAvatarCode,
    'receiverAvatarFileId': receiverAvatarFileId,
    'capabilities': capabilities,
  };
}
