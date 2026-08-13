import '../entities/notification_message_page_result.dart';
import '../repositories/notification_message_repository.dart';

class FetchNotificationMessagesUseCase {
  const FetchNotificationMessagesUseCase({required this.repository});
  final NotificationMessageRepository repository;
  Future<NotificationMessagePageResult> call({
    required int page,
    required int pageSize,
    required String requestId,
  }) => repository.fetchMessages(
    page: page,
    pageSize: pageSize,
    requestId: requestId,
  );
}
