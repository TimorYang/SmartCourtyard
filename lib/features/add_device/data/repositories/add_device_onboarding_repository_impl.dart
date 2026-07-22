import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/onboarded_force_door.dart';
import '../../domain/entities/onboarding_device_key.dart';
import '../../domain/repositories/add_device_onboarding_repository.dart';
import '../data_sources/add_device_onboarding_remote_data_source.dart';
import '../dto/force_door_response_dto.dart';
import '../dto/onboarding_device_key_response_dto.dart';

class AddDeviceOnboardingRepositoryImpl
    implements AddDeviceOnboardingRepository {
  const AddDeviceOnboardingRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final AddDeviceOnboardingRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<OnboardingDeviceKey> fetchDeviceKey({
    required String sn,
    required String requestId,
  }) async {
    try {
      final data = await remoteDataSource.fetchDeviceKey(
        sn: sn,
        requestId: requestId,
      );
      logger.info(
        'Fetched onboarding device key.',
        tag: AppLogTag.binding,
        flowId: _flowId(requestId),
        requestId: requestId,
        context: {'sn': sn, 'aesKeyVersion': data.aesKeyVersion},
      );
      return data.toDomain();
    } on AddDeviceOnboardingRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to fetch onboarding device key.',
        tag: AppLogTag.binding,
        flowId: _flowId(requestId),
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'sn': sn, 'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId, 'addDevice.deviceKeyFailed');
    }
  }

  @override
  Future<OnboardedForceDoor> addForceDoor({
    required String sn,
    required String requestId,
  }) async {
    try {
      final data = await remoteDataSource.addForceDoor(
        sn: sn,
        requestId: requestId,
      );
      logger.info(
        'Added force door after onboarding.',
        tag: AppLogTag.binding,
        flowId: _flowId(requestId),
        requestId: requestId,
        context: {'sn': sn, 'doorId': data.id},
      );
      return data.toDomain(sn: sn);
    } on AddDeviceOnboardingRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to add force door after onboarding.',
        tag: AppLogTag.binding,
        flowId: _flowId(requestId),
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'sn': sn, 'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId, 'addDevice.bindDoorFailed');
    }
  }

  AppError _mapError(
    AddDeviceOnboardingRemoteException error,
    String requestId,
    String messageKey,
  ) {
    final resolvedMessageKey =
        _messageKeyForServerMessageKey(error.serverMessageKey) ?? messageKey;
    if (error.kind == AddDeviceOnboardingRemoteErrorKind.network) {
      return AppError(
        code: AppErrorCode.networkUnavailable,
        messageKey: resolvedMessageKey,
        action: AppErrorAction.retry,
        requestId: requestId,
        retryable: true,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: resolvedMessageKey,
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }

  String? _messageKeyForServerMessageKey(String? serverMessageKey) {
    return switch (serverMessageKey) {
      'app.door.device_not_exists' => 'addDevice.deviceNotExists',
      _ => null,
    };
  }

  String _flowId(String requestId) => requestId.split(':').first;
}

extension OnboardingDeviceKeyResponseDtoMapper
    on OnboardingDeviceKeyResponseDto {
  OnboardingDeviceKey toDomain() {
    return OnboardingDeviceKey(
      sn: sn,
      aesKey: aesKey,
      aesKeyVersion: aesKeyVersion,
    );
  }
}

extension ForceDoorResponseDtoMapper on ForceDoorResponseDto {
  OnboardedForceDoor toDomain({required String sn}) {
    return OnboardedForceDoor(id: id, sn: sn, name: name);
  }
}
