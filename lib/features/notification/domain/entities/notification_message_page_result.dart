import 'app_notification.dart';

class NotificationMessagePageResult {
  const NotificationMessagePageResult({
    required this.messages,
    required this.currentPage,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  final List<AppNotification> messages;
  final int currentPage;
  final int pageSize;
  final int total;
  final bool hasMore;
}
