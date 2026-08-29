import 'api_envelope_dto.dart';

/// Structured details for an HTTP-success response rejected by its business
/// envelope.
class ApiBusinessFailure {
  ApiBusinessFailure({required this.code, String? message, String? messageKey})
    : message = _normalize(message),
      messageKey = _normalize(messageKey);

  static ApiBusinessFailure fromEnvelope<T>(ApiEnvelopeDto<T> envelope) {
    return ApiBusinessFailure(
      code: envelope.code,
      message: envelope.msg,
      messageKey: envelope.messageKey,
    );
  }

  final int code;
  final String? message;
  final String? messageKey;

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
