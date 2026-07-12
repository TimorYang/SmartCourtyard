// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_envelope_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiEnvelopeDto<T> _$ApiEnvelopeDtoFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => $checkedCreate('_ApiEnvelopeDto', json, ($checkedConvert) {
  final val = _ApiEnvelopeDto<T>(
    code: $checkedConvert('code', (v) => (v as num).toInt()),
    success: $checkedConvert('success', (v) => v as bool),
    msg: $checkedConvert('msg', (v) => v as String?),
    data: $checkedConvert(
      'data',
      (v) => _$nullableGenericFromJson(v, fromJsonT),
    ),
  );
  return val;
});

Map<String, dynamic> _$ApiEnvelopeDtoToJson<T>(
  _ApiEnvelopeDto<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'code': instance.code,
  'success': instance.success,
  'msg': instance.msg,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);
