class ReceivingDoorResponseDto {
  const ReceivingDoorResponseDto({
    required this.shareId,
    required this.doorId,
    required this.name,
    required this.coverFileId,
    this.doorType,
    required this.ownerEmail,
    required this.expiresAt,
  });

  final int shareId;
  final int doorId;

  /// Card title supplied by the receiving-door API.
  final String name;

  final int? coverFileId;
  final int? doorType;

  /// Card subtitle supplied by the receiving-door API.
  final String ownerEmail;

  /// UTC expiry timestamp in milliseconds; null means the share never expires.
  final int? expiresAt;

  factory ReceivingDoorResponseDto.fromJson(Map<String, dynamic> json) {
    final shareId = _parseInt(json['shareId']);
    final doorId = _parseInt(json['doorId']);
    if (shareId == null || doorId == null) {
      throw const FormatException(
        'Receiving door response is missing shareId or doorId.',
      );
    }
    return ReceivingDoorResponseDto(
      shareId: shareId,
      doorId: doorId,
      name: json['name'] as String? ?? '',
      coverFileId: _parseInt(json['coverFileId']),
      doorType: _parseInt(json['doorType']),
      ownerEmail: json['ownerEmail'] as String? ?? '',
      expiresAt: _parseInt(json['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'shareId': shareId,
    'doorId': doorId,
    'name': name,
    'coverFileId': coverFileId,
    'doorType': doorType,
    'ownerEmail': ownerEmail,
    'expiresAt': expiresAt,
  };

  static int? _parseInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
