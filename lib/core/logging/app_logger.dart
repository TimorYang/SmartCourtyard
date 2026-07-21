import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum AppLogTag {
  general('FLINX'),
  binding('FLINX_BIND'),
  ble('FLINX_BLE');

  const AppLogTag(this.value);

  final String value;
}

abstract interface class AppLogger {
  void info(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  });

  void warning(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  });

  void error(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
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
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {
    _write(
      'INFO',
      message,
      tag: tag,
      flowId: flowId,
      requestId: requestId,
      context: context,
    );
  }

  @override
  void warning(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {
    _write(
      'WARNING',
      message,
      tag: tag,
      flowId: flowId,
      requestId: requestId,
      context: context,
    );
  }

  @override
  void error(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _write(
      'ERROR',
      message,
      tag: tag,
      flowId: flowId,
      requestId: requestId,
      context: context,
      // Error strings can contain request bodies or credentials. Keep only the
      // type in diagnostics; structured context is already independently
      // redacted above.
      error: error?.runtimeType.toString(),
      stackTrace: stackTrace,
    );
  }

  void _write(
    String level,
    String message, {
    required AppLogTag tag,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    final safeContext = _redactedContext(context);
    final structuredMessage =
        '$level event=$message '
        'onboardingFlowId=${flowId ?? '-'} '
        'requestId=${requestId ?? '-'} context=$safeContext';
    developer.log(
      structuredMessage,
      name: tag.value,
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
    // VSCode's Flutter Debug Console reliably receives Flutter stdout, while
    // dart:developer events can be hidden in profile/release sessions. This is
    // safe in every build because context and error values are redacted above.
    debugPrint(
      '[${tag.value}][$level] event=$message '
      'onboardingFlowId=${flowId ?? '-'} requestId=${requestId ?? '-'} '
      'context=$safeContext',
    );
  }

  Map<String, Object?> _redactedContext(Map<String, Object?> context) {
    return context.map((key, value) {
      final lowerKey = key.toLowerCase();
      if (lowerKey.contains('authorization') ||
          lowerKey.contains('credential') ||
          lowerKey.contains('token') ||
          lowerKey.contains('password') ||
          lowerKey.contains('nonce') ||
          lowerKey.contains('secret') ||
          lowerKey == 'aeskey' ||
          lowerKey.endsWith('keyhex') ||
          lowerKey.contains('sessionkey') ||
          lowerKey.contains('devicekey')) {
        return MapEntry(key, '<redacted>');
      }
      if (value is Map<String, Object?>) {
        return MapEntry(key, _redactedContext(value));
      }
      return MapEntry(key, value);
    });
  }
}
