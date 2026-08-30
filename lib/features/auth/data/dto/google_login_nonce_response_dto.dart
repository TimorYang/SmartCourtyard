class GoogleLoginNonceResponseDto {
  const GoogleLoginNonceResponseDto({
    required this.nonceId,
    required this.nonce,
    required this.expiresInSeconds,
  });

  final String nonceId;
  final String nonce;
  final int expiresInSeconds;

  factory GoogleLoginNonceResponseDto.fromJson(Map<String, dynamic> json) {
    return GoogleLoginNonceResponseDto(
      nonceId: json['nonceId'] as String? ?? '',
      nonce: json['nonce'] as String? ?? '',
      expiresInSeconds: _intValue(json['expiresIn']),
    );
  }
}

int _intValue(Object? value) => switch (value) {
  final num number => number.toInt(),
  final String text => int.tryParse(text.trim()) ?? 0,
  _ => 0,
};
