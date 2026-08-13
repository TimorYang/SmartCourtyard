import '../entities/app_notification.dart';
import '../repositories/notification_message_repository.dart';

class FetchNotificationDetailUseCase {
  const FetchNotificationDetailUseCase({required this.repository});
  final NotificationMessageRepository repository;
  Future<AppNotificationDetail> call({
    required String messageId,
    required String requestId,
  }) =>
      repository.fetchMessageDetail(messageId: messageId, requestId: requestId);
}
