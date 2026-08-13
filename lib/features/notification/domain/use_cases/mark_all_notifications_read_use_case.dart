import '../repositories/notification_message_repository.dart';

class MarkAllNotificationsReadUseCase {
  const MarkAllNotificationsReadUseCase({required this.repository});
  final NotificationMessageRepository repository;
  Future<void> call({required String requestId}) =>
      repository.markAllRead(requestId: requestId);
}
