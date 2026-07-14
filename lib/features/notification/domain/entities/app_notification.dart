enum NotificationAction { viewDetails, appointmentAfterSales, upgrade }

enum NotificationKind {
  appointmentConfirmed, //预约已确认
  appointmentReminder, //预约提醒
  upgrade, //升级
  lowBattery, //电池电量低
  motorResetWarning, //电机次数即将清零
  sensorAbnormality, //传感器异常
  systemMaintenance, //系统维护
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.category,
    required this.summary,
    required this.timestamp,
    required this.detail,
    required this.action,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String category;
  final String summary;
  final String timestamp;
  final String detail;
  final NotificationAction action;
}
