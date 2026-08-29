import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
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
  Future<void> validateBindingStatus({
    required String sn,
    required String requestId,
  }) async {
    try {
      await remoteDataSource.validateBindingStatus(
        sn: sn,
        requestId: requestId,
      );
      logger.info(
        'Validated onboarding binding status.',
        tag: AppLogTag.binding,
        flowId: _flowId(requestId),
        requestId: requestId,
        context: {'sn': sn},
      );
    } on AddDeviceOnboardingRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to validate onboarding binding status.',
        tag: AppLogTag.binding,
        flowId: _flowId(requestId),
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'sn': sn,
          'statusCode': error.statusCode,
          'businessCode': error.businessFailure?.code,
          'businessMessageKey': error.businessFailure?.messageKey,
        },
      );
      throw _mapError(error, requestId, 'addDevice.bindingStatusFailed');
    }
  }

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
        context: {
          'sn': sn,
          'statusCode': error.statusCode,
          'businessCode': error.businessFailure?.code,
          'businessMessageKey': error.businessFailure?.messageKey,
        },
      );
      throw _mapError(error, requestId, 'addDevice.deviceKeyFailed');
    }
  }

  @override
  Future<OnboardedForceDoor> addForceDoor({
    required String sn,
    String? doorId,
    int? sceneId,
    required int doorType,
    required String requestId,
  }) async {
    try {
      final data = await remoteDataSource.addForceDoor(
        sn: sn,
        doorId: doorId,
        sceneId: sceneId,
        doorType: doorType,
        requestId: requestId,
      );
      logger.info(
        'Added force door after onboarding.',
        tag: AppLogTag.binding,
        flowId: _flowId(requestId),
        requestId: requestId,
        context: {
          'sn': sn,
          'doorId': data.id,
          'doorType': doorType,
          'sceneId': sceneId,
        },
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
        context: {
          'sn': sn,
          'statusCode': error.statusCode,
          'businessCode': error.businessFailure?.code,
          'businessMessageKey': error.businessFailure?.messageKey,
        },
      );
      throw _mapError(error, requestId, 'addDevice.bindDoorFailed');
    }
  }

  AppError _mapError(
    AddDeviceOnboardingRemoteException error,
    String requestId,
    String messageKey,
  ) {
    final bindingStatusError = switch (error.kind) {
      AddDeviceOnboardingRemoteErrorKind.alreadyBoundToCurrentUser =>
        'addDevice.deviceAlreadyBoundToCurrentUser',
      AddDeviceOnboardingRemoteErrorKind.alreadyBoundToAnotherUser =>
        'addDevice.deviceAlreadyBoundToAnotherUser',
      _ => null,
    };
    if (bindingStatusError != null) {
      return AppError(
        code: AppErrorCode.accessDenied,
        messageKey: bindingStatusError,
        action: AppErrorAction.none,
        requestId: requestId,
      );
    }
    final localizedBusinessMessageKey = _messageKeyForServerMessageKey(
      error.businessFailure?.messageKey,
    );
    final resolvedMessageKey = localizedBusinessMessageKey ?? messageKey;
    if (error.kind == AddDeviceOnboardingRemoteErrorKind.network &&
        error.network != null) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: resolvedMessageKey,
      action: AppErrorAction.retry,
      requestId: requestId,
      businessCode: error.businessFailure?.code,
      businessMessageKey: error.businessFailure?.messageKey,
      userMessage: localizedBusinessMessageKey == null
          ? error.businessFailure?.message
          : null,
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
