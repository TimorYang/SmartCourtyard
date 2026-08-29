import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/managed_login_device.dart';
import '../../domain/repositories/managed_devices_repository.dart';
import '../data_sources/managed_devices_remote_data_source.dart';
import '../dto/managed_login_device_dto.dart';

class ManagedDevicesRepositoryImpl implements ManagedDevicesRepository {
  const ManagedDevicesRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final ManagedDevicesRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<List<ManagedLoginDevice>> fetchLoginDevices({
    required String requestId,
  }) async {
    try {
      final devices = await remoteDataSource.fetchLoginDevices(
        requestId: requestId,
      );
      logger.info(
        'Fetched managed login devices.',
        requestId: requestId,
        context: {'deviceCount': devices.length},
      );
      return devices.map((device) => device.toDomain()).toList(growable: false);
    } on ManagedDevicesRemoteException catch (error, stackTrace) {
      throw _mapError(error, requestId, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> removeLoginDevice({
    required String sessionId,
    required String requestId,
  }) async {
    try {
      await remoteDataSource.removeLoginDevice(
        sessionId: sessionId,
        requestId: requestId,
      );
      logger.info(
        'Removed managed login device.',
        requestId: requestId,
        context: {'sessionId': sessionId},
      );
    } on ManagedDevicesRemoteException catch (error, stackTrace) {
      throw _mapError(
        error,
        requestId,
        stackTrace: stackTrace,
        sessionId: sessionId,
      );
    }
  }

  AppError _mapError(
    ManagedDevicesRemoteException error,
    String requestId, {
    required StackTrace stackTrace,
    String? sessionId,
  }) {
    logger.error(
      'Managed login device request failed.',
      requestId: requestId,
      error: error,
      stackTrace: stackTrace,
      context: {'sessionId': sessionId, 'statusCode': error.statusCode},
    );
    if (error.kind == ManagedDevicesRemoteErrorKind.network &&
        error.network != null) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'managedDevices.failed',
      businessCode: error.businessFailure?.code,
      businessMessageKey: error.businessFailure?.messageKey,
      userMessage: error.kind == ManagedDevicesRemoteErrorKind.businessFailure
          ? error.businessFailure?.message
          : null,
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }
}

extension ManagedLoginDeviceDtoMapper on ManagedLoginDeviceDto {
  ManagedLoginDevice toDomain() => ManagedLoginDevice(
    sessionId: sessionId,
    deviceModel: deviceModel?.trim(),
    platform: ManagedLoginDevicePlatform.fromWireValue(platform),
    lastLoginTime: lastLoginTime,
    currentDevice: currentDevice,
  );
}
