import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_envelope_dto.freezed.dart';
part 'api_envelope_dto.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class ApiEnvelopeDto<T> with _$ApiEnvelopeDto<T> {
  const factory ApiEnvelopeDto({
    required int code,
    required bool success,
    String? msg,
    T? data,
  }) = _ApiEnvelopeDto<T>;

  factory ApiEnvelopeDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiEnvelopeDtoFromJson(json, fromJsonT);
}
