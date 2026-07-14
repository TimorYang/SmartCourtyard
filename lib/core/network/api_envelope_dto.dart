import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_envelope_dto.freezed.dart';

@Freezed(genericArgumentFactories: true)
abstract class ApiEnvelopeDto<T> with _$ApiEnvelopeDto<T> {
  const factory ApiEnvelopeDto({
    required int code,
    required bool success,
    String? msg,
    String? messageKey,
    T? data,
  }) = _ApiEnvelopeDto<T>;

  factory ApiEnvelopeDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return _$ApiEnvelopeDtoFromJson(json, fromJsonT);
  }
}

ApiEnvelopeDto<T> _$ApiEnvelopeDtoFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) {
  final success = json['success'] as bool;
  final dataJson = json['data'];
  return ApiEnvelopeDto<T>(
    code: (json['code'] as num).toInt(),
    success: success,
    msg: json['msg'] as String?,
    messageKey: json['messageKey'] as String?,
    data: success && dataJson != null ? fromJsonT(dataJson) : null,
  );
}
