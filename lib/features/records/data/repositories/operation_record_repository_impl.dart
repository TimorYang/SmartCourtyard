import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../account/domain/entities/account_avatar_code.dart';
import '../../domain/entities/operation_record.dart';
import '../../domain/entities/operation_record_page_result.dart';
import '../../domain/repositories/operation_record_repository.dart';
import '../data_sources/operation_record_remote_data_source.dart';
import '../dto/operation_report_request_dto.dart';
import '../dto/operation_record_response_dto.dart';

class OperationRecordRepositoryImpl implements OperationRecordRepository {
  const OperationRecordRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final OperationRecordRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<void> reportOperation({
    required String doorId,
    required OperationReportAction action,
    required OperationReportSource operationSource,
    required String requestId,
  }) async {
    final parsedDoorId = _parseDoorId(
      doorId,
      requestId,
      messageKey: 'operation_report_invalid_door_id',
    );
    try {
      await remoteDataSource.reportOperation(
        doorId: parsedDoorId,
        body: OperationReportRequestDto(
          action: action,
          operationSource: operationSource,
        ),
        requestId: requestId,
      );
    } on OperationRecordRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to report door operation',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'doorId': doorId,
          'action': action.wireValue,
          'operationSource': operationSource.wireValue,
          'errorKind': error.kind.name,
        },
      );
      throw _mapError(
        error,
        requestId,
        doorId,
        messageKey: 'operation_report_invalid_response',
      );
    }
  }

  @override
  Future<OperationRecordPageResult> fetchOperationRecords({
    required String doorId,
    required int page,
    required int pageSize,
    required String requestId,
  }) async {
    final parsedDoorId = _parseDoorId(
      doorId,
      requestId,
      messageKey: 'operation_record_invalid_door_id',
    );
    try {
      final dto = await remoteDataSource.fetchOperationRecords(
        doorId: parsedDoorId,
        page: page,
        pageSize: pageSize,
        requestId: requestId,
      );
      return dto.toDomain(requestedPage: page, requestedPageSize: pageSize);
    } on OperationRecordRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to fetch operation records',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'page': page, 'errorKind': error.kind.name},
      );
      throw _mapError(
        error,
        requestId,
        doorId,
        messageKey: 'operation_record_invalid_response',
      );
    }
  }

  int _parseDoorId(
    String doorId,
    String requestId, {
    required String messageKey,
  }) {
    final parsedDoorId = int.tryParse(doorId.trim());
    if (parsedDoorId == null) {
      throw AppError(
        code: AppErrorCode.unknown,
        messageKey: messageKey,
        requestId: requestId,
        deviceId: doorId,
      );
    }
    return parsedDoorId;
  }

  AppError _mapError(
    OperationRecordRemoteException error,
    String requestId,
    String doorId, {
    required String messageKey,
  }) {
    if (error.kind == OperationRecordRemoteErrorKind.network &&
        error.network != null) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
        deviceId: doorId,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: messageKey,
      businessCode: error.businessFailure?.code,
      businessMessageKey: error.businessFailure?.messageKey,
      userMessage: error.kind == OperationRecordRemoteErrorKind.businessFailure
          ? error.businessFailure?.message
          : null,
      action: AppErrorAction.retry,
      requestId: requestId,
      deviceId: doorId,
      retryable: true,
    );
  }
}

extension OperationRecordPageResponseDtoMapper
    on OperationRecordPageResponseDto {
  OperationRecordPageResult toDomain({
    required int requestedPage,
    required int requestedPageSize,
  }) {
    final currentPage = current != null && current! > 0
        ? current!
        : requestedPage;
    final resolvedPageSize = size != null && size! > 0
        ? size!
        : requestedPageSize;
    final resolvedTotal = total != null && total! >= 0
        ? total!
        : records.length;
    return OperationRecordPageResult(
      records: records
          .map((record) => record.toDomain())
          .toList(growable: false),
      currentPage: currentPage,
      pageSize: resolvedPageSize,
      total: resolvedTotal,
      hasMore: currentPage * resolvedPageSize < resolvedTotal,
    );
  }
}

extension OperationRecordResponseDtoMapper on OperationRecordResponseDto {
  OperationRecord toDomain() => OperationRecord(
    action: switch (action?.trim().toUpperCase()) {
      'OPEN' => OperationRecordAction.open,
      'CLOSE' => OperationRecordAction.close,
      'STOP' => OperationRecordAction.stop,
      'PARTIAL_OPEN' => OperationRecordAction.partialOpen,
      'AUTO_CLOSE_TOGGLE' => OperationRecordAction.autoCloseToggle,
      'LED_ON' => OperationRecordAction.ledOn,
      'LED_OFF' => OperationRecordAction.ledOff,
      'LED_OFF_DELAY_CHANGED' => OperationRecordAction.ledOffDelayChanged,
      'PARTIAL_OPEN_CHANGED' => OperationRecordAction.partialOpenChanged,
      'AUTO_CLOSE_DELAY_CHANGED' => OperationRecordAction.autoCloseDelayChanged,
      'DOOR_OPEN_REMINDER_TOGGLE' =>
        OperationRecordAction.doorOpenReminderToggle,
      'DOOR_OPEN_REMINDER_DELAY_CHANGED' =>
        OperationRecordAction.doorOpenReminderDelayChanged,
      _ => OperationRecordAction.unknown,
    },
    occurredAt: occurredAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            occurredAt!,
            isUtc: true,
          ).toLocal(),
    doorName: doorName,
    operatorAccount: operatorAccount,
    operatorName: operatorName,
    operatorAvatarCode: AccountAvatarCode.fromWireValue(operatorAvatarCode),
    operatorAvatarFileId: operatorAvatarFileId,
    operationMethodLabel: operationMethodLabel,
  );
}
