abstract interface class AppLogger {
  void info(
    String message, {
    String? requestId,
    Map<String, Object?> context = const {},
  });

  void warning(
    String message, {
    String? requestId,
    Map<String, Object?> context = const {},
  });

  void error(
    String message, {
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  });
}

class DebugAppLogger implements AppLogger {
  const DebugAppLogger();

  @override
  void info(
    String message, {
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void warning(
    String message, {
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void error(
    String message, {
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}
}
