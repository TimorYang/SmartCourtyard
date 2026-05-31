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
    this.requestId,
    this.deviceId,
    this.retryable = false,
  });

  final AppErrorCode code;
  final String messageKey;
  final AppErrorAction action;
  final String? nativeCode;
  final String? requestId;
  final String? deviceId;
  final bool retryable;

  @override
  String toString() {
    return 'AppError(code: $code, messageKey: $messageKey, action: $action)';
  }
}
