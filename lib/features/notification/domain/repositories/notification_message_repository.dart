import '../entities/app_notification.dart';
import '../entities/notification_message_page_result.dart';

abstract interface class NotificationMessageRepository {
  Future<NotificationMessagePageResult> fetchMessages({
    required int page,
    required int pageSize,
    required String requestId,
  });
  Future<AppNotificationDetail> fetchMessageDetail({
    required String messageId,
    required String requestId,
  });
  Future<void> markAllRead({required String requestId});
  Future<bool> fetchUnreadState({required String requestId});
}
