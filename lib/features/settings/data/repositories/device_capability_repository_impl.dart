import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/device_capability.dart';
import '../../domain/repositories/device_capability_repository.dart';
import '../data_sources/device_capability_remote_data_source.dart';

class DeviceCapabilityRepositoryImpl implements DeviceCapabilityRepository {
  const DeviceCapabilityRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final DeviceCapabilityRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<List<DeviceCapability>> fetchCapabilities({
    required String deviceId,
    required String requestId,
  }) async {
    try {
      final capabilities = await remoteDataSource.fetchCapabilities(
        deviceId: deviceId,
        requestId: requestId,
      );
      return capabilities
          .where((capability) => capability.code.trim().isNotEmpty)
          .map(
            (capability) => DeviceCapability(
              code: capability.code.trim(),
              label: capability.label.trim(),
              unit: capability.unit?.trim(),
              options: capability.options
                  .map(
                    (option) => DeviceCapabilityOption(
                      value: option.value,
                      label: option.label.trim(),
                    ),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false);
    } on DeviceCapabilityRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to fetch device capabilities',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'deviceId': deviceId, 'errorKind': error.kind.name},
      );
      if (error.kind == DeviceCapabilityRemoteErrorKind.network &&
          error.network != null) {
        throw mapNetworkExceptionToAppError(
          error.network!,
          requestId: requestId,
          deviceId: deviceId,
        );
      }
      throw AppError(
        code: AppErrorCode.serverError,
        messageKey: 'device_capabilities_invalid_response',
        businessCode: error.businessFailure?.code,
        businessMessageKey: error.businessFailure?.messageKey,
        userMessage:
            error.kind == DeviceCapabilityRemoteErrorKind.businessFailure
            ? error.businessFailure?.message
            : null,
        action: AppErrorAction.retry,
        requestId: requestId,
        deviceId: deviceId,
        retryable: true,
      );
    }
  }
}
