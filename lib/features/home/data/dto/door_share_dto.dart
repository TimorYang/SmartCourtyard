class ShareCapabilityResponseDto {
  const ShareCapabilityResponseDto({required this.code, this.label});
  final String code;
  final String? label;

  factory ShareCapabilityResponseDto.fromJson(Map<String, dynamic> json) =>
      ShareCapabilityResponseDto(
        code: json['code'] as String? ?? '',
        label: json['label'] as String?,
      );
  Map<String, dynamic> toJson() => {'code': code, 'label': label};
}

class CreateDoorShareRequestDto {
  const CreateDoorShareRequestDto({
    required this.receiverEmail,
    required this.role,
    required this.expiryType,
    required this.capabilities,
    this.expiresAt,
  });
  final String receiverEmail;
  final String role;
  final String expiryType;
  final List<String> capabilities;
  final int? expiresAt;

  factory CreateDoorShareRequestDto.fromJson(Map<String, dynamic> json) =>
      CreateDoorShareRequestDto(
        receiverEmail: json['receiverEmail'] as String? ?? '',
        role: json['role'] as String? ?? '',
        expiryType: json['expiryType'] as String? ?? '',
        capabilities: (json['capabilities'] as List<Object?>? ?? const [])
            .whereType<String>()
            .toList(growable: false),
        expiresAt: (json['expiresAt'] as num?)?.toInt(),
      );
  Map<String, dynamic> toJson() => {
    'receiverEmail': receiverEmail,
    'role': role,
    'expiryType': expiryType,
    'capabilities': capabilities,
    if (expiresAt != null) 'expiresAt': expiresAt,
  };
}

class UpdateDoorShareRequestDto {
  const UpdateDoorShareRequestDto({
    required this.role,
    required this.expiryType,
    required this.capabilities,
    this.expiresAt,
  });

  final String role;
  final String expiryType;
  final List<String> capabilities;
  final int? expiresAt;

  factory UpdateDoorShareRequestDto.fromJson(Map<String, dynamic> json) =>
      UpdateDoorShareRequestDto(
        role: json['role'] as String? ?? '',
        expiryType: json['expiryType'] as String? ?? '',
        capabilities: (json['capabilities'] as List<Object?>? ?? const [])
            .whereType<String>()
            .toList(growable: false),
        expiresAt: (json['expiresAt'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
    'role': role,
    'expiryType': expiryType,
    'capabilities': capabilities,
    if (expiresAt != null) 'expiresAt': expiresAt,
  };
}

class DoorShareRecipientResponseDto {
  const DoorShareRecipientResponseDto({required this.shareId});
  final int? shareId;

  factory DoorShareRecipientResponseDto.fromJson(Map<String, dynamic> json) =>
      DoorShareRecipientResponseDto(
        shareId: _parseNullableInt(json['shareId']),
      );
  Map<String, dynamic> toJson() => {'shareId': shareId};

  static int? _parseNullableInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
