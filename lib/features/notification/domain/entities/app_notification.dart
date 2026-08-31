enum NotificationKind {
  appointmentConfirmed, //预约已确认
  appointmentReminder, //预约提醒
  upgrade, //升级
  lowBattery, //电池电量低
  motorResetWarning, //电机次数即将清零
  sensorAbnormality, //传感器异常
  systemMaintenance, //系统维护
}

enum NotificationColorTag { red, green, blue, unknown }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.templateCode,
    required this.type,
    required this.kind,
    this.colorTag = NotificationColorTag.unknown,
    required this.title,
    required this.category,
    required this.summary,
    required this.timestamp,
    required this.isRead,
  });

  final String id;
  final String templateCode;
  final String type;
  final NotificationKind kind;
  final NotificationColorTag colorTag;
  final String title;
  final String category;
  final String summary;
  final String timestamp;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    templateCode: templateCode,
    type: type,
    kind: kind,
    colorTag: colorTag,
    title: title,
    category: category,
    summary: summary,
    timestamp: timestamp,
    isRead: isRead ?? this.isRead,
  );
}

class AppNotificationDetail {
  const AppNotificationDetail({
    required this.id,
    required this.templateCode,
    required this.type,
    required this.title,
    required this.category,
    required this.content,
    required this.mobileLink,
    required this.isRead,
    required this.timestamp,
  });

  final String id;
  final String templateCode;
  final String type;
  final String title;
  final String category;
  final String content;
  final String? mobileLink;
  final bool isRead;
  final String timestamp;
}
