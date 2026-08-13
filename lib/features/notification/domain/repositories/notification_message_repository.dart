import '../entities/app_notification.dart';

abstract interface class NotificationMessageRepository {
  Future<List<AppNotification>> fetchMessages({required String requestId});
  Future<AppNotificationDetail> fetchMessageDetail({
    required String messageId,
    required String requestId,
  });
  Future<void> markAllRead({required String requestId});
  Future<bool> fetchUnreadState({required String requestId});
}
