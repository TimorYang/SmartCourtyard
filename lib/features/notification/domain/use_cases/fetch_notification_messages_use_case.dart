import '../entities/app_notification.dart';
import '../repositories/notification_message_repository.dart';

class FetchNotificationMessagesUseCase {
  const FetchNotificationMessagesUseCase({required this.repository});
  final NotificationMessageRepository repository;
  Future<List<AppNotification>> call({required String requestId}) =>
      repository.fetchMessages(requestId: requestId);
}
