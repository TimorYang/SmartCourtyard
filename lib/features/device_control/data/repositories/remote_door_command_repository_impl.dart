import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/network_exception.dart';
import '../../domain/entities/remote_door_command.dart';
import '../../domain/repositories/remote_door_command_repository.dart';
import '../data_sources/remote_door_command_remote_data_source.dart';
import '../dto/remote_door_command_request_dto.dart';
import '../dto/remote_door_command_response_dto.dart';

class RemoteDoorCommandRepositoryImpl implements RemoteDoorCommandRepository {
  const RemoteDoorCommandRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final RemoteDoorCommandRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<RemoteDoorCommand> submitCommand({
    required String doorId,
    required RemoteDoorCommandAction action,
    required String requestId,
  }) async {
    final parsedDoorId = _parseDoorId(doorId, requestId);
    try {
      final dto = await remoteDataSource.submitCommand(
        doorId: parsedDoorId,
        body: RemoteDoorCommandRequestDto(action: action),
        requestId: requestId,
      );
      return _mapAndValidate(dto, doorId, action, requestId);
    } on RemoteDoorCommandRemoteException catch (error, stackTrace) {
      throw _mapError(error, doorId, requestId, stackTrace);
    }
  }

  int _parseDoorId(String doorId, String requestId) {
    final parsed = int.tryParse(doorId.trim());
    if (parsed == null) {
      throw AppError(
        code: AppErrorCode.unknown,
        messageKey: 'remote_door_command_invalid_door_id',
        requestId: requestId,
        deviceId: doorId,
      );
    }
    return parsed;
  }

  RemoteDoorCommand _mapAndValidate(
    RemoteDoorCommandResponseDto dto,
    String doorId,
    RemoteDoorCommandAction? expectedAction,
    String requestId,
  ) {
    final action = _actionFromWire(dto.action);
    if (action == null ||
        (expectedAction != null && action != expectedAction) ||
        dto.doorId.trim() != doorId.trim()) {
      throw _invalidResponse(doorId, requestId);
    }
    return RemoteDoorCommand(
      commandId: dto.commandId.trim(),
      doorId: dto.doorId.trim(),
      action: action,
      status: _statusFromWire(dto.status),
      commandType: dto.commandType,
      stateConfirmationStatus: dto.stateConfirmationStatus,
      deviceResultCode: dto.deviceResultCode,
      failureCategory: dto.failureCategory,
      failureReason: dto.failureReason,
      createdAt: dto.createdAt,
      publishedAt: dto.publishedAt,
      deviceAckAt: dto.deviceAckAt,
      stateReportedAt: dto.stateReportedAt,
    );
  }

  RemoteDoorCommandAction? _actionFromWire(String value) {
    for (final action in RemoteDoorCommandAction.values) {
      if (action.wireValue == value.trim().toUpperCase()) {
        return action;
      }
    }
    return null;
  }

  RemoteDoorCommandStatus _statusFromWire(String value) {
    return switch (value.trim().toUpperCase()) {
      'PROCESSING' => RemoteDoorCommandStatus.processing,
      'SUCCEEDED' => RemoteDoorCommandStatus.succeeded,
      'FAILED' => RemoteDoorCommandStatus.failed,
      'UNCONFIRMED' => RemoteDoorCommandStatus.unconfirmed,
      _ => RemoteDoorCommandStatus.unknown,
    };
  }

  AppError _mapError(
    RemoteDoorCommandRemoteException error,
    String doorId,
    String requestId,
    StackTrace stackTrace,
  ) {
    logger.error(
      'Remote door command request failed',
      requestId: requestId,
      error: error,
      stackTrace: stackTrace,
      context: {'doorId': doorId, 'errorKind': error.kind.name},
    );
    if (error.kind == RemoteDoorCommandRemoteErrorKind.network &&
        error.network?.category == NetworkFailureCategory.networkUnavailable) {
      return AppError(
        code: AppErrorCode.networkUnavailable,
        messageKey: 'remote_door_command_network_unavailable',
        action: AppErrorAction.retry,
        requestId: requestId,
        deviceId: doorId,
        retryable: true,
      );
    }
    return _invalidResponse(
      doorId,
      requestId,
      userMessage:
          error.kind == RemoteDoorCommandRemoteErrorKind.businessFailure
          ? error.businessFailure?.message
          : null,
    );
  }

  AppError _invalidResponse(
    String doorId,
    String requestId, {
    String? userMessage,
  }) {
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'remote_door_command_invalid_response',
      userMessage: userMessage,
      action: AppErrorAction.retry,
      requestId: requestId,
      deviceId: doorId,
      retryable: true,
    );
  }
}
