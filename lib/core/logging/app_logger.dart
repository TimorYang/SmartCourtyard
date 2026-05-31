import 'dart:developer' as developer;

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
  }) {
    _write('INFO', message, requestId: requestId, context: context);
  }

  @override
  void warning(
    String message, {
    String? requestId,
    Map<String, Object?> context = const {},
  }) {
    _write('WARNING', message, requestId: requestId, context: context);
  }

  @override
  void error(
    String message, {
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _write(
      'ERROR',
      message,
      requestId: requestId,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _write(
    String level,
    String message, {
    String? requestId,
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      '$level $message',
      name: 'FLINX',
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
      sequenceNumber: DateTime.now().microsecondsSinceEpoch,
      level: switch (level) {
        'ERROR' => 1000,
        'WARNING' => 900,
        _ => 800,
      },
      zone: null,
    );
    if (requestId != null || context.isNotEmpty) {
      developer.log(
        'requestId=${requestId ?? '-'} context=${_redactedContext(context)}',
        name: 'FLINX',
      );
    }
  }

  Map<String, Object?> _redactedContext(Map<String, Object?> context) {
    return context.map((key, value) {
      final lowerKey = key.toLowerCase();
      if (lowerKey.contains('token') ||
          lowerKey.contains('password') ||
          lowerKey.contains('secret') ||
          lowerKey.contains('key')) {
        return MapEntry(key, '<redacted>');
      }
      return MapEntry(key, value);
    });
  }
}
