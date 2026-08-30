class FacebookLoginNonceResponseDto {
  const FacebookLoginNonceResponseDto({
    required this.nonceId,
    required this.nonce,
    required this.expiresInSeconds,
  });

  final String nonceId;
  final String nonce;
  final int expiresInSeconds;

  factory FacebookLoginNonceResponseDto.fromJson(Map<String, dynamic> json) {
    return FacebookLoginNonceResponseDto(
      nonceId: _stringValue(json['nonceId']),
      nonce: _stringValue(json['nonce']),
      expiresInSeconds: _intValue(json['expiresIn']),
    );
  }
}

String _stringValue(Object? value) => value is String ? value : '';

int _intValue(Object? value) => switch (value) {
  final num number => number.toInt(),
  final String text => int.tryParse(text.trim()) ?? 0,
  _ => 0,
};
