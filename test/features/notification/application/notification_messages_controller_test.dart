import 'dart:async';

import 'package:flinx/features/notification/application/notification_messages_controller.dart';
import 'package:flinx/features/notification/application/providers.dart';
import 'package:flinx/features/notification/domain/entities/app_notification.dart';
import 'package:flinx/features/notification/domain/entities/notification_message_page_result.dart';
import 'package:flinx/features/notification/domain/repositories/notification_message_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requests 20 items and appends the next page', () async {
    final repository = _RecordingRepository(
      <int, NotificationMessagePageResult>{
        1: _page(<AppNotification>[_message('1')], hasMore: true),
        2: _page(<AppNotification>[_message('2')], page: 2),
      },
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      notificationMessagesControllerProvider.notifier,
    );

    await controller.loadInitial();
    await controller.loadMore();

    final state = container.read(notificationMessagesControllerProvider);
    expect(state.messages.map((item) => item.id), <String>['1', '2']);
    expect(repository.requestedPages, <int>[1, 2]);
    expect(repository.requestedPageSizes, <int>[20, 20]);
  });

  test('refresh replaces messages with the first page', () async {
    final repository = _RecordingRepository(
      <int, NotificationMessagePageResult>{
        1: _page(<AppNotification>[_message('before')]),
      },
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      notificationMessagesControllerProvider.notifier,
    );

    await controller.loadInitial();
    repository.pages[1] = _page(<AppNotification>[_message('after')]);
    await controller.refresh();

    expect(
      container.read(notificationMessagesControllerProvider).messages.single.id,
      'after',
    );
    expect(repository.requestedPages, <int>[1, 1]);
  });

  test('does not load more after the last page', () async {
    final repository = _RecordingRepository(
      <int, NotificationMessagePageResult>{
        1: _page(<AppNotification>[_message('1')]),
      },
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      notificationMessagesControllerProvider.notifier,
    );

    await controller.loadInitial();
    await controller.loadMore();

    expect(repository.requestedPages, <int>[1]);
  });

  test('ignores duplicate load-more requests while one is pending', () async {
    final pendingPage = Completer<NotificationMessagePageResult>();
    final repository = _RecordingRepository(
      <int, NotificationMessagePageResult>{
        1: _page(<AppNotification>[_message('1')], hasMore: true),
      },
      pendingPage: pendingPage,
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      notificationMessagesControllerProvider.notifier,
    );

    await controller.loadInitial();
    final firstRequest = controller.loadMore();
    final duplicateRequest = controller.loadMore();

    expect(repository.requestedPages, <int>[1, 2]);
    pendingPage.complete(_page(<AppNotification>[_message('2')], page: 2));
    await Future.wait<void>(<Future<void>>[firstRequest, duplicateRequest]);
  });

  test('synchronizes a read detail into the loaded message list', () async {
    final repository = _RecordingRepository(
      <int, NotificationMessagePageResult>{
        1: _page(<AppNotification>[_message('1'), _message('2')]),
      },
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      notificationMessagesControllerProvider.notifier,
    );

    await controller.loadInitial();
    controller.synchronizeMessageReadState(messageId: '1', isRead: true);

    final messages = container.read(notificationMessagesControllerProvider).messages;
    expect(messages.first.isRead, isTrue);
    expect(messages.last.isRead, isFalse);
  });
}

ProviderContainer _container(NotificationMessageRepository repository) =>
    ProviderContainer(
      overrides: [
        notificationMessageRepositoryProvider.overrideWithValue(repository),
      ],
    );

AppNotification _message(String id) => AppNotification(
  id: id,
  templateCode: 'DEVICE_ABNORMAL',
  type: 'DEVICE',
  kind: NotificationKind.lowBattery,
  title: 'Message $id',
  category: 'Device',
  summary: 'Summary $id',
  timestamp: '2026-08-13 20:00:00',
  isRead: false,
);

NotificationMessagePageResult _page(
  List<AppNotification> messages, {
  int page = 1,
  bool hasMore = false,
}) => NotificationMessagePageResult(
  messages: messages,
  currentPage: page,
  pageSize: 20,
  total: hasMore ? 21 : messages.length,
  hasMore: hasMore,
);

class _RecordingRepository implements NotificationMessageRepository {
  _RecordingRepository(this.pages, {this.pendingPage});

  final Map<int, NotificationMessagePageResult> pages;
  final Completer<NotificationMessagePageResult>? pendingPage;
  final List<int> requestedPages = <int>[];
  final List<int> requestedPageSizes = <int>[];

  @override
  Future<NotificationMessagePageResult> fetchMessages({
    required int page,
    required int pageSize,
    required String requestId,
  }) {
    requestedPages.add(page);
    requestedPageSizes.add(pageSize);
    if (page == 2 && pendingPage != null) return pendingPage!.future;
    return Future<NotificationMessagePageResult>.value(pages[page]!);
  }

  @override
  Future<AppNotificationDetail> fetchMessageDetail({
    required String messageId,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<bool> fetchUnreadState({required String requestId}) async => false;

  @override
  Future<void> markAllRead({required String requestId}) async {}
}
