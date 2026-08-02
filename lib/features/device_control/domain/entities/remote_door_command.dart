enum RemoteDoorCommandAction {
  open('OPEN'),
  close('CLOSE'),
  stop('STOP'),
  ledOn('LED_ON'),
  ledOff('LED_OFF');

  const RemoteDoorCommandAction(this.wireValue);

  final String wireValue;
}

enum RemoteDoorCommandStatus {
  processing,
  succeeded,
  failed,
  unconfirmed,
  unknown;

  bool get isTerminal =>
      this == RemoteDoorCommandStatus.succeeded ||
      this == RemoteDoorCommandStatus.failed ||
      this == RemoteDoorCommandStatus.unconfirmed;
}

class RemoteDoorCommand {
  const RemoteDoorCommand({
    required this.commandId,
    required this.doorId,
    required this.action,
    required this.status,
    this.commandType,
    this.stateConfirmationStatus,
    this.deviceResultCode,
    this.failureCategory,
    this.failureReason,
    this.createdAt,
    this.publishedAt,
    this.deviceAckAt,
    this.stateReportedAt,
  });

  final String commandId;
  final String doorId;
  final RemoteDoorCommandAction action;
  final RemoteDoorCommandStatus status;
  final String? commandType;
  final String? stateConfirmationStatus;
  final int? deviceResultCode;
  final String? failureCategory;
  final String? failureReason;
  final int? createdAt;
  final int? publishedAt;
  final int? deviceAckAt;
  final int? stateReportedAt;
}
