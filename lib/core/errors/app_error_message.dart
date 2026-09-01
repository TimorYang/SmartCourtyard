import 'app_error.dart';

/// Returns the human-readable server message carried by an [AppError], or the
/// caller's localized fallback when no server message is available.
String appErrorMessage(Object? error, String fallback) {
  if (error is! AppError) return fallback;
  final message = error.userMessage?.trim();
  return message == null || message.isEmpty ? fallback : message;
}
