class AuthLoginResponseDto {
  const AuthLoginResponseDto({
    required this.accountId,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresInSeconds,
    required this.refreshExpiresInSeconds,
  });

  final String accountId;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInSeconds;
  final int refreshExpiresInSeconds;

  factory AuthLoginResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthLoginResponseDto(
      accountId: json['account_id'] as String? ?? '',
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? '',
      expiresInSeconds: (json['expires_in'] as num?)?.toInt() ?? 0,
      refreshExpiresInSeconds:
          (json['refresh_expires_in'] as num?)?.toInt() ?? 0,
    );
  }
}
