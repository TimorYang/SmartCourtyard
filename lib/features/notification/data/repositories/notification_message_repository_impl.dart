import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/app_notification.dart';
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
  Future<List<AppNotification>> fetchMessages({
    required String requestId,
  }) async {
    try {
      final page = await remoteDataSource.fetchMessages(requestId: requestId);
      return page.records
          .map((item) => item.toDomain())
          .toList(growable: false);
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
        (error.statusCode == 401 || error.statusCode == 403)) {
      return AppError(
        code: AppErrorCode.accessDenied,
        messageKey: 'notification.accessDenied',
        requestId: requestId,
      );
    }
    if (error.kind == NotificationMessageRemoteErrorKind.network) {
      return AppError(
        code: AppErrorCode.networkUnavailable,
        messageKey: 'notification.networkUnavailable',
        action: AppErrorAction.retry,
        requestId: requestId,
        retryable: true,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'notification.failed',
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
    kind: _notificationKind(templateCode, type),
    title: title,
    category: label,
    summary: summary,
    timestamp: createTime,
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
    timestamp: createTime,
  );
}

NotificationKind _notificationKind(String templateCode, String type) {
  final code = templateCode.trim().toUpperCase();
  if (code.contains('APPOINTMENT') && code.contains('REMIND')) {
    return NotificationKind.appointmentReminder;
  }
  if (code.contains('APPOINTMENT') || code.contains('SERVICE_ORDER')) {
    return NotificationKind.appointmentConfirmed;
  }
  if (code.contains('UPGRADE') || type.trim().toUpperCase() == 'FIRMWARE') {
    return NotificationKind.upgrade;
  }
  if (code.contains('BATTERY')) {
    return NotificationKind.lowBattery;
  }
  if (code.contains('MOTOR') || code.contains('RESET')) {
    return NotificationKind.motorResetWarning;
  }
  if (code.contains('SENSOR') || type.trim().toUpperCase() == 'SECURITY') {
    return NotificationKind.sensorAbnormality;
  }
  return NotificationKind.systemMaintenance;
}
