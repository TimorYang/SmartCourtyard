import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_public_key_response_dto.freezed.dart';
part 'auth_public_key_response_dto.g.dart';

@freezed
abstract class AuthPublicKeyResponseDto with _$AuthPublicKeyResponseDto {
  const factory AuthPublicKeyResponseDto({
    required String keyId,
    required String algorithm,
    required String publicKey,
    required String nonce,
    @JsonKey(name: 'expiresIn', fromJson: _expiresInSecondsFromJson)
    required int expiresInSeconds,
  }) = _AuthPublicKeyResponseDto;

  factory AuthPublicKeyResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthPublicKeyResponseDtoFromJson(json);
}

int _expiresInSecondsFromJson(Object? value) {
  return switch (value) {
    final int seconds when seconds > 0 => seconds,
    final String seconds => int.parse(seconds.trim()),
    _ => throw const FormatException('expiresIn must be a positive integer.'),
  };
}
