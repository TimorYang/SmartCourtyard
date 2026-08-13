import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/app_notification.dart';
import '../domain/entities/notification_message_page_result.dart';
import '../domain/use_cases/fetch_notification_messages_use_case.dart';
import '../domain/use_cases/mark_all_notifications_read_use_case.dart';
import 'providers.dart';

class NotificationMessagesState {
  const NotificationMessagesState({
    this.messages = const <AppNotification>[],
    this.currentPage = 0,
    this.hasMore = true,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.initialLoadFailed = false,
    this.loadMoreFailed = false,
  });

  final List<AppNotification> messages;
  final int currentPage;
  final bool hasMore;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool initialLoadFailed;
  final bool loadMoreFailed;

  NotificationMessagesState copyWith({
    List<AppNotification>? messages,
    int? currentPage,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? initialLoadFailed,
    bool? loadMoreFailed,
  }) => NotificationMessagesState(
    messages: messages ?? this.messages,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
    isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    initialLoadFailed: initialLoadFailed ?? this.initialLoadFailed,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

final notificationMessagesControllerProvider =
    NotifierProvider<NotificationMessagesController, NotificationMessagesState>(
      NotificationMessagesController.new,
    );

class NotificationMessagesController
    extends Notifier<NotificationMessagesState> {
  static const pageSize = 20;

  late final FetchNotificationMessagesUseCase _fetchMessages;
  late final MarkAllNotificationsReadUseCase _markAllRead;
  int _requestCounter = 0;

  @override
  NotificationMessagesState build() {
    _fetchMessages = ref.watch(fetchNotificationMessagesUseCaseProvider);
    _markAllRead = ref.watch(markAllNotificationsReadUseCaseProvider);
    return const NotificationMessagesState();
  }

  Future<void> loadInitial() async {
    if (state.isInitialLoading || state.isRefreshing) return;
    state = state.copyWith(isInitialLoading: true, initialLoadFailed: false);
    try {
      final result = await _fetchPage(1, 'initial');
      state = state.copyWith(
        messages: result.messages,
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isInitialLoading: false,
        initialLoadFailed: false,
        loadMoreFailed: false,
      );
    } catch (_) {
      state = state.copyWith(isInitialLoading: false, initialLoadFailed: true);
    }
  }

  Future<void> refresh() async {
    if (state.isInitialLoading || state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true, initialLoadFailed: false);
    try {
      final result = await _fetchPage(1, 'refresh');
      state = state.copyWith(
        messages: result.messages,
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isRefreshing: false,
        initialLoadFailed: false,
        loadMoreFailed: false,
      );
    } catch (_) {
      state = state.copyWith(
        isRefreshing: false,
        initialLoadFailed: state.messages.isEmpty,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading ||
        state.isRefreshing ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final result = await _fetchPage(state.currentPage + 1, 'more');
      final existingIds = state.messages.map((item) => item.id).toSet();
      final newMessages = result.messages.where(
        (item) => existingIds.add(item.id),
      );
      state = state.copyWith(
        messages: <AppNotification>[...state.messages, ...newMessages],
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
        loadMoreFailed: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false, loadMoreFailed: true);
    }
  }

  Future<bool> markAllRead() async {
    if (state.isInitialLoading || state.isRefreshing || state.isLoadingMore) {
      return false;
    }
    try {
      await _markAllRead(requestId: _nextRequestId('mark-all-read'));
      state = state.copyWith(
        messages: state.messages
            .map((message) => message.copyWith(isRead: true))
            .toList(growable: false),
      );
      ref.invalidate(notificationUnreadStateProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<NotificationMessagePageResult> _fetchPage(
    int page,
    String operation,
  ) => _fetchMessages(
    page: page,
    pageSize: pageSize,
    requestId: _nextRequestId(operation),
  );

  String _nextRequestId(String operation) {
    _requestCounter += 1;
    return 'notification-messages-$operation-'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}-$_requestCounter';
  }
}
