enum OperationReportAction {
  open('OPEN'),
  close('CLOSE'),
  stop('STOP'),
  autoCloseToggle('AUTO_CLOSE_TOGGLE'),
  ledOn('LED_ON'),
  ledOff('LED_OFF'),
  ledOffDelayChanged('LED_OFF_DELAY_CHANGED'),
  partialOpenChanged('PARTIAL_OPEN_CHANGED'),
  autoCloseDelayChanged('AUTO_CLOSE_DELAY_CHANGED'),
  doorOpenReminderToggle('DOOR_OPEN_REMINDER_TOGGLE'),
  doorOpenReminderDelayChanged('DOOR_OPEN_REMINDER_DELAY_CHANGED');

  const OperationReportAction(this.wireValue);

  final String wireValue;
}

enum OperationReportSource {
  bluetooth('BLUETOOTH'),
  app('APP');

  const OperationReportSource(this.wireValue);

  final String wireValue;
}
