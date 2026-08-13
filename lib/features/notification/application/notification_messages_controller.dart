import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/app_notification.dart';
import '../domain/use_cases/fetch_notification_messages_use_case.dart';
import '../domain/use_cases/mark_all_notifications_read_use_case.dart';
import 'providers.dart';

final notificationMessagesControllerProvider =
    AsyncNotifierProvider<
      NotificationMessagesController,
      List<AppNotification>
    >(NotificationMessagesController.new);

class NotificationMessagesController
    extends AsyncNotifier<List<AppNotification>> {
  FetchNotificationMessagesUseCase get _fetchMessages =>
      ref.read(fetchNotificationMessagesUseCaseProvider);
  MarkAllNotificationsReadUseCase get _markAllRead =>
      ref.read(markAllNotificationsReadUseCaseProvider);

  @override
  Future<List<AppNotification>> build() async => const [];

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchMessages(
        requestId:
            'notification-messages-${DateTime.now().toUtc().microsecondsSinceEpoch}',
      ),
    );
  }

  Future<bool> markAllRead() async {
    if (state.isLoading) return false;
    try {
      await _markAllRead(
        requestId:
            'notification-mark-all-read-${DateTime.now().toUtc().microsecondsSinceEpoch}',
      );
      final messages = state.asData?.value ?? const <AppNotification>[];
      state = AsyncData(
        messages
            .map((message) => message.copyWith(isRead: true))
            .toList(growable: false),
      );
      ref.invalidate(notificationUnreadStateProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}
