import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_message_page_result.dart';
import '../../domain/repositories/notification_message_repository.dart';
import '../data_sources/notification_message_remote_data_source.dart';
import '../dto/notification_message_dto.dart';

class NotificationMessageRepositoryImpl
    implements NotificationMessageRepository {
  const NotificationMessageRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final NotificationMessageRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<NotificationMessagePageResult> fetchMessages({
    required int page,
    required int pageSize,
    required String requestId,
  }) async {
    try {
      final result = await remoteDataSource.fetchMessages(
        page: page,
        pageSize: pageSize,
        requestId: requestId,
      );
      final currentPage = int.parse(result.current);
      final responsePageSize = int.parse(result.size);
      final total = int.parse(result.total);
      return NotificationMessagePageResult(
        messages: result.records
            .map((item) => item.toDomain())
            .toList(growable: false),
        currentPage: currentPage,
        pageSize: responsePageSize,
        total: total,
        hasMore: currentPage * responsePageSize < total,
      );
    } on NotificationMessageRemoteException catch (error, stackTrace) {
      throw _mapError(error, requestId, stackTrace);
    }
  }

  @override
  Future<AppNotificationDetail> fetchMessageDetail({
    required String messageId,
    required String requestId,
  }) async {
    try {
      return (await remoteDataSource.fetchMessageDetail(
        messageId: messageId,
        requestId: requestId,
      )).toDomain();
    } on NotificationMessageRemoteException catch (error, stackTrace) {
      throw _mapError(error, requestId, stackTrace, messageId: messageId);
    }
  }

  @override
  Future<void> markAllRead({required String requestId}) async {
    try {
      await remoteDataSource.markAllRead(requestId: requestId);
    } on NotificationMessageRemoteException catch (error, stackTrace) {
      throw _mapError(error, requestId, stackTrace);
    }
  }

  @override
  Future<bool> fetchUnreadState({required String requestId}) async {
    try {
      return (await remoteDataSource.fetchUnreadState(
        requestId: requestId,
      )).hasUnread;
    } on NotificationMessageRemoteException catch (error, stackTrace) {
      throw _mapError(error, requestId, stackTrace);
    }
  }

  AppError _mapError(
    NotificationMessageRemoteException error,
    String requestId,
    StackTrace stackTrace, {
    String? messageId,
  }) {
    logger.error(
      'Notification message request failed.',
      requestId: requestId,
      error: error,
      stackTrace: stackTrace,
      context: {'messageId': messageId, 'statusCode': error.statusCode},
    );
    if (error.kind == NotificationMessageRemoteErrorKind.network &&
        error.network != null) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'notification.failed',
      businessCode: error.businessFailure?.code,
      businessMessageKey: error.businessFailure?.messageKey,
      userMessage:
          error.kind == NotificationMessageRemoteErrorKind.businessFailure
          ? error.businessFailure?.message
          : null,
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }
}

extension NotificationMessageCardDtoMapper on NotificationMessageCardDto {
  AppNotification toDomain() => AppNotification(
    id: id,
    templateCode: templateCode,
    type: type,
    colorTag: _notificationColorTag(colorTag),
    title: title,
    category: label,
    summary: summary,
    timestamp: _formatTimestamp(createTime),
    isRead: read,
  );
}

extension NotificationMessageDetailDtoMapper on NotificationMessageDetailDto {
  AppNotificationDetail toDomain() => AppNotificationDetail(
    id: id,
    templateCode: templateCode,
    type: type,
    title: title,
    category: label,
    content: content,
    mobileLink: mobileLink?.trim().isEmpty == true ? null : mobileLink?.trim(),
    isRead: read,
    timestamp: _formatTimestamp(createTime),
  );
}

NotificationColorTag _notificationColorTag(String? value) =>
    switch (value?.trim().toUpperCase()) {
      'RED' => NotificationColorTag.red,
      'GREEN' => NotificationColorTag.green,
      'BLUE' => NotificationColorTag.blue,
      _ => NotificationColorTag.unknown,
    };

String _formatTimestamp(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return '';

  DateTime? timestamp;
  final milliseconds = int.tryParse(normalized);
  if (milliseconds != null) {
    try {
      timestamp = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    } on ArgumentError {
      return normalized;
    }
  } else {
    timestamp = DateTime.tryParse(normalized);
  }
  if (timestamp == null) return normalized;

  final local = timestamp.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}:'
      '${twoDigits(local.second)}';
}
