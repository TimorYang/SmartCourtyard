import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/providers.dart';
import '../../../core/network/providers.dart';
import '../data/data_sources/notification_message_api.dart';
import '../data/data_sources/notification_message_remote_data_source.dart';
import '../data/repositories/notification_message_repository_impl.dart';
import '../domain/entities/app_notification.dart';
import '../domain/repositories/notification_message_repository.dart';
import '../domain/use_cases/fetch_notification_detail_use_case.dart';
import '../domain/use_cases/fetch_notification_messages_use_case.dart';
import '../domain/use_cases/mark_all_notifications_read_use_case.dart';

final notificationMessageApiProvider = Provider<NotificationMessageApi>(
  (ref) => NotificationMessageApi(ref.watch(dioProvider)),
);
final notificationMessageRemoteDataSourceProvider =
    Provider<NotificationMessageRemoteDataSource>(
      (ref) => NotificationMessageRemoteDataSourceImpl(
        api: ref.watch(notificationMessageApiProvider),
      ),
    );
final notificationMessageRepositoryProvider =
    Provider<NotificationMessageRepository>(
      (ref) => NotificationMessageRepositoryImpl(
        remoteDataSource: ref.watch(
          notificationMessageRemoteDataSourceProvider,
        ),
        logger: ref.watch(appLoggerProvider),
      ),
    );
final fetchNotificationMessagesUseCaseProvider =
    Provider<FetchNotificationMessagesUseCase>(
      (ref) => FetchNotificationMessagesUseCase(
        repository: ref.watch(notificationMessageRepositoryProvider),
      ),
    );
final fetchNotificationDetailUseCaseProvider =
    Provider<FetchNotificationDetailUseCase>(
      (ref) => FetchNotificationDetailUseCase(
        repository: ref.watch(notificationMessageRepositoryProvider),
      ),
    );
final markAllNotificationsReadUseCaseProvider =
    Provider<MarkAllNotificationsReadUseCase>(
      (ref) => MarkAllNotificationsReadUseCase(
        repository: ref.watch(notificationMessageRepositoryProvider),
      ),
    );

final notificationDetailProvider = FutureProvider.autoDispose
    .family<AppNotificationDetail, String>(
      (ref, messageId) => ref.watch(fetchNotificationDetailUseCaseProvider)(
        messageId: messageId,
        requestId:
            'notification-detail-$messageId-${DateTime.now().toUtc().microsecondsSinceEpoch}',
      ),
    );
final notificationUnreadStateProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref
      .watch(notificationMessageRepositoryProvider)
      .fetchUnreadState(
        requestId:
            'notification-unread-state-${DateTime.now().toUtc().microsecondsSinceEpoch}',
      ),
);
