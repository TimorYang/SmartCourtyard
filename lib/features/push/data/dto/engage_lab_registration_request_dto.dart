import 'package:freezed_annotation/freezed_annotation.dart';

part 'engage_lab_registration_request_dto.freezed.dart';
part 'engage_lab_registration_request_dto.g.dart';

@freezed
abstract class EngageLabRegistrationRequestDto
    with _$EngageLabRegistrationRequestDto {
  const factory EngageLabRegistrationRequestDto({
    required String registrationId,
    required String deviceId,
    required String platform,
  }) = _EngageLabRegistrationRequestDto;

  factory EngageLabRegistrationRequestDto.fromJson(Map<String, dynamic> json) =>
      _$EngageLabRegistrationRequestDtoFromJson(json);
}
