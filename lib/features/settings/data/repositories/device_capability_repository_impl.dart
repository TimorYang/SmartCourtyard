import '../../../../core/errors/app_error.dart';
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
      throw AppError(
        code: error.kind == DeviceCapabilityRemoteErrorKind.network
            ? AppErrorCode.networkUnavailable
            : AppErrorCode.serverError,
        messageKey: error.kind == DeviceCapabilityRemoteErrorKind.network
            ? 'device_capabilities_network_unavailable'
            : 'device_capabilities_invalid_response',
        action: AppErrorAction.retry,
        requestId: requestId,
        deviceId: deviceId,
        retryable: true,
      );
    }
  }
}
