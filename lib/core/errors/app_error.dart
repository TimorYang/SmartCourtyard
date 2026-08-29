enum AppErrorCode {
  permissionDenied,
  bluetoothUnavailable,
  bluetoothDisconnected,
  deviceOffline,
  deviceBusy,
  commandTimeout,
  provisioningFailed,
  pairingFailed,
  accessDenied,
  networkUnavailable,
  serverError,
  unknown,
}

enum AppErrorAction {
  openSettings,
  connectBluetooth,
  retry,
  contactSupport,
  none,
}

class AppError implements Exception {
  const AppError({
    required this.code,
    required this.messageKey,
    this.action = AppErrorAction.none,
    this.nativeCode,
    this.businessCode,
    this.businessMessageKey,
    this.userMessage,
    this.requestId,
    this.deviceId,
    this.retryable = false,
  });

  final AppErrorCode code;
  final String messageKey;
  final AppErrorAction action;

  /// Server business response code retained for support diagnostics and
  /// feature-level error handling. This is never a native hardware code.
  final int? businessCode;

  /// Server-provided stable message key, if the API contract supplies one.
  /// Presentation code must map only recognized values to localizations.
  final String? businessMessageKey;

  final String? nativeCode;
  final String? userMessage;
  final String? requestId;
  final String? deviceId;
  final bool retryable;

  @override
  String toString() {
    return 'AppError(code: $code, messageKey: $messageKey, '
        'businessCode: $businessCode, businessMessageKey: $businessMessageKey, '
        'action: $action)';
  }
}
