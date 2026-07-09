enum NotificationAction { viewDetails, appointmentAfterSales, upgrade }

enum NotificationKind {
  appointmentConfirmed,
  appointmentReminder,
  upgrade,
  lowBattery,
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
