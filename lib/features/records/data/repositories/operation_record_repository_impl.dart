import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/operation_record.dart';
import '../../domain/entities/operation_record_page_result.dart';
import '../../domain/repositories/operation_record_repository.dart';
import '../data_sources/operation_record_remote_data_source.dart';
import '../dto/operation_record_response_dto.dart';

class OperationRecordRepositoryImpl implements OperationRecordRepository {
  const OperationRecordRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final OperationRecordRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<OperationRecordPageResult> fetchOperationRecords({
    required String doorId,
    required int page,
    required int pageSize,
    required String requestId,
  }) async {
    final parsedDoorId = int.tryParse(doorId.trim());
    if (parsedDoorId == null) {
      throw AppError(
        code: AppErrorCode.unknown,
        messageKey: 'operation_record_invalid_door_id',
        requestId: requestId,
        deviceId: doorId,
      );
    }
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
      throw _mapError(error, requestId, doorId);
    }
  }

  AppError _mapError(
    OperationRecordRemoteException error,
    String requestId,
    String doorId,
  ) {
    if (error.kind == OperationRecordRemoteErrorKind.network) {
      return AppError(
        code: AppErrorCode.networkUnavailable,
        messageKey: 'operation_record_network_unavailable',
        action: AppErrorAction.retry,
        requestId: requestId,
        deviceId: doorId,
        retryable: true,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'operation_record_invalid_response',
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
      'LED_ON' => OperationRecordAction.ledOn,
      'LED_OFF' => OperationRecordAction.ledOff,
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
    operatorAvatarFileId: operatorAvatarFileId,
    operationMethodLabel: operationMethodLabel,
  );
}
