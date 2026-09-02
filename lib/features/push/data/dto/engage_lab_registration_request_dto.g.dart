// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engage_lab_registration_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EngageLabRegistrationRequestDto _$EngageLabRegistrationRequestDtoFromJson(
  Map<String, dynamic> json,
) =>
    $checkedCreate('_EngageLabRegistrationRequestDto', json, ($checkedConvert) {
      final val = _EngageLabRegistrationRequestDto(
        registrationId: $checkedConvert('registrationId', (v) => v as String),
        deviceId: $checkedConvert('deviceId', (v) => v as String),
        platform: $checkedConvert('platform', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$EngageLabRegistrationRequestDtoToJson(
  _EngageLabRegistrationRequestDto instance,
) => <String, dynamic>{
  'registrationId': instance.registrationId,
  'deviceId': instance.deviceId,
  'platform': instance.platform,
};
