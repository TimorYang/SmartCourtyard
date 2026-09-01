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
  final code = (json['code'] as num).toInt();
  final success = json['success'] as bool;
  final dataJson = json['data'];
  final message = _readMessage(json['msg']) ?? _readMessage(json['message']);
  return ApiEnvelopeDto<T>(
    code: code,
    success: success,
    msg: message,
    messageKey: _readMessage(json['messageKey']),
    data: code == 200 && success && dataJson != null
        ? fromJsonT(dataJson)
        : null,
  );
}

String? _readMessage(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

/// The REST protocol considers a response successful only when both fields
/// explicitly indicate success. In particular, legacy code 0 is a failure.
extension ApiEnvelopeDtoBusinessSuccess<T> on ApiEnvelopeDto<T> {
  bool get isBusinessSuccess => code == 200 && success;
}
