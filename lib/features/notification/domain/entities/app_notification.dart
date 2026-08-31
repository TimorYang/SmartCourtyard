enum NotificationColorTag { red, green, blue, unknown }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.templateCode,
    required this.type,
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
