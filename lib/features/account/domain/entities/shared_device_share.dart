/// A device and the people who currently have access to it.
class SharedDeviceShare {
  const SharedDeviceShare({
    required this.deviceId,
    required this.deviceName,
    required this.members,
  });

  /// Stable device identifier used by future member-management operations.
  /// Displayed by implication in the page header; required String; example `garage-door-001`.
  final String deviceId;

  /// Human-readable device name shown at the top of the member-management page.
  /// Required String; example `Garage door`.
  final String deviceName;

  /// People with access to the device, rendered in role-specific page sections.
  /// Required list; example contains administrators and guests.
  final List<SharedDeviceMember> members;

  factory SharedDeviceShare.fromJson(Map<String, dynamic> json) {
    return SharedDeviceShare(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      members: (json['members'] as List<dynamic>)
          .map(
            (member) =>
                SharedDeviceMember.fromJson(member as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'members': members.map((member) => member.toJson()).toList(),
    };
  }

  factory SharedDeviceShare.mock() {
    const avatarAssetPath = SharedDeviceMemberAssetPaths.avatarPlaceholder;
    return SharedDeviceShare(
      deviceId: 'garage-door-001',
      deviceName: 'Garage door',
      members: [
        SharedDeviceMember.mock(
          id: 'member-admin-001',
          role: SharedDeviceMemberRole.administrator,
          avatarAssetPath: avatarAssetPath,
        ),
        SharedDeviceMember.mock(
          id: 'member-admin-002',
          role: SharedDeviceMemberRole.administrator,
          avatarAssetPath: avatarAssetPath,
        ),
        SharedDeviceMember.mock(
          id: 'member-guest-001',
          role: SharedDeviceMemberRole.guest,
          avatarAssetPath: avatarAssetPath,
        ),
        SharedDeviceMember.mock(
          id: 'member-guest-002',
          role: SharedDeviceMemberRole.guest,
          avatarAssetPath: avatarAssetPath,
        ),
      ],
    );
  }
}

/// A person granted access to a shared device.
class SharedDeviceMember {
  const SharedDeviceMember({
    required this.id,
    required this.role,
    required this.avatarAssetPath,
    required this.email,
    required this.authorizedAt,
    required this.status,
  });

  /// Stable member identifier for a future edit or removal request.
  /// Not directly rendered; required String; example `member-admin-001`.
  final String id;

  /// Access level used to place the member in the Administrator or Guest section.
  /// Required enum; example `SharedDeviceMemberRole.administrator`.
  final SharedDeviceMemberRole role;

  /// Avatar cut-asset path shown at the leading edge of the member card.
  /// Required String; example `assets/images/account/shared_device_member_avatar_placeholder.png`.
  final String avatarAssetPath;

  /// Member account email shown as the primary text on the card.
  /// Required String; example `Andy@forcedoor.cn`.
  final String email;

  /// Time at which the member was authorized, shown below their email.
  /// Required DateTime; example `2025-10-16 17:54:28`.
  final DateTime authorizedAt;

  /// Invitation/access state shown as the final text line in the card.
  /// Required enum; example `SharedDeviceMemberStatus.accepted`.
  final SharedDeviceMemberStatus status;

  factory SharedDeviceMember.fromJson(Map<String, dynamic> json) {
    return SharedDeviceMember(
      id: json['id'] as String,
      role: SharedDeviceMemberRole.values.byName(json['role'] as String),
      avatarAssetPath: json['avatarAssetPath'] as String,
      email: json['email'] as String,
      authorizedAt: DateTime.parse(json['authorizedAt'] as String),
      status: SharedDeviceMemberStatus.values.byName(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'avatarAssetPath': avatarAssetPath,
      'email': email,
      'authorizedAt': authorizedAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory SharedDeviceMember.mock({
    required String id,
    required SharedDeviceMemberRole role,
    required String avatarAssetPath,
  }) {
    return SharedDeviceMember(
      id: id,
      role: role,
      avatarAssetPath: avatarAssetPath,
      email: 'Andy@forcedoor.cn',
      authorizedAt: DateTime(2025, 10, 16, 17, 54, 28),
      status: SharedDeviceMemberStatus.accepted,
    );
  }
}

/// Access categories supported by the shared-device member-management page.
enum SharedDeviceMemberRole { administrator, guest }

/// Invitation states supported by the shared-device member-management page.
enum SharedDeviceMemberStatus { accepted }

/// Replace these placeholder cut assets with the final member-management art.
class SharedDeviceMemberAssetPaths {
  const SharedDeviceMemberAssetPaths._();

  static const avatarPlaceholder =
      'assets/images/account/shared_device_member_avatar_placeholder.png';
  static const editAction =
      'assets/icons/account/shared_device_member_edit_placeholder.png';
  static const deleteAction =
      'assets/icons/account/shared_device_member_delete_placeholder.png';
}
