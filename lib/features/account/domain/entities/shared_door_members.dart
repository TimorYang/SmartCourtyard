class SharedDoorMembers {
  const SharedDoorMembers({
    required this.doorId,
    required this.doorName,
    required this.administrators,
    required this.guests,
  });
  final int doorId;
  final String doorName;
  final List<SharedDoorMember> administrators;
  final List<SharedDoorMember> guests;
}

class SharedDoorMember {
  const SharedDoorMember({
    required this.doorId,
    required this.shareId,
    required this.email,
    required this.role,
    required this.expiryType,
    required this.capabilityCodes,
    this.expiresAt,
    this.receiverAvatarFileId,
  });
  final int doorId;
  final int shareId;
  final String email;
  final SharedDoorMemberRole role;
  final SharedDoorMemberExpiryType expiryType;
  final List<String> capabilityCodes;
  final DateTime? expiresAt;
  final int? receiverAvatarFileId;

  String get id => shareId.toString();
}

enum SharedDoorMemberRole { administrator, guest }

enum SharedDoorMemberExpiryType { neverExpired, twoHours, customize }
