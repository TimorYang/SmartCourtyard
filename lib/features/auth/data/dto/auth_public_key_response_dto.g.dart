// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_public_key_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthPublicKeyResponseDto _$AuthPublicKeyResponseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_AuthPublicKeyResponseDto',
  json,
  ($checkedConvert) {
    final val = _AuthPublicKeyResponseDto(
      keyId: $checkedConvert('keyId', (v) => v as String),
      algorithm: $checkedConvert('algorithm', (v) => v as String),
      publicKey: $checkedConvert('publicKey', (v) => v as String),
      nonce: $checkedConvert('nonce', (v) => v as String),
      expiresInSeconds: $checkedConvert(
        'expiresIn',
        (v) => _expiresInSecondsFromJson(v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'expiresInSeconds': 'expiresIn'},
);

Map<String, dynamic> _$AuthPublicKeyResponseDtoToJson(
  _AuthPublicKeyResponseDto instance,
) => <String, dynamic>{
  'keyId': instance.keyId,
  'algorithm': instance.algorithm,
  'publicKey': instance.publicKey,
  'nonce': instance.nonce,
  'expiresIn': instance.expiresInSeconds,
};
