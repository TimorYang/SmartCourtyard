class ReceivingDoorResponseDto {
  const ReceivingDoorResponseDto({
    required this.shareId,
    required this.doorId,
    required this.name,
    required this.coverFileId,
    required this.ownerEmail,
    required this.expiresAt,
  });

  final int shareId;
  final int doorId;

  /// Card title supplied by the receiving-door API.
  final String name;

  /// Retained for API fidelity; cover rendering is not connected yet.
  final int? coverFileId;

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
      ownerEmail: json['ownerEmail'] as String? ?? '',
      expiresAt: _parseInt(json['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'shareId': shareId,
    'doorId': doorId,
    'name': name,
    'coverFileId': coverFileId,
    'ownerEmail': ownerEmail,
    'expiresAt': expiresAt,
  };

  static int? _parseInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
