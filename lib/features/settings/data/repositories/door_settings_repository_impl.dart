import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/door_setting_snapshot.dart';
import '../../domain/repositories/door_settings_repository.dart';
import '../data_sources/door_settings_remote_data_source.dart';

class DoorSettingsRepositoryImpl implements DoorSettingsRepository {
  const DoorSettingsRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final DoorSettingsRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<List<DoorSettingSnapshot>> fetchSettings({
    required String doorId,
    required String requestId,
  }) async {
    final parsedDoorId = int.tryParse(doorId.trim());
    if (parsedDoorId == null) {
      throw AppError(
        code: AppErrorCode.unknown,
        messageKey: 'door_settings_invalid_door_id',
        requestId: requestId,
        deviceId: doorId,
      );
    }
    try {
      final settings = await remoteDataSource.fetchSettings(
        doorId: parsedDoorId,
        requestId: requestId,
      );
      return settings
          .where((setting) => setting.code.trim().isNotEmpty)
          .map(
            (setting) => DoorSettingSnapshot(
              code: setting.code.trim(),
              label: setting.label.trim(),
              supported: setting.supported,
              configured: setting.configured,
              currentValue: setting.currentValue,
              unit: setting.unit?.trim(),
            ),
          )
          .toList(growable: false);
    } on DoorSettingsRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to fetch door settings',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'errorKind': error.kind.name},
      );
      throw AppError(
        code: error.kind == DoorSettingsRemoteErrorKind.network
            ? AppErrorCode.networkUnavailable
            : AppErrorCode.serverError,
        messageKey: error.kind == DoorSettingsRemoteErrorKind.network
            ? 'door_settings_network_unavailable'
            : 'door_settings_invalid_response',
        action: AppErrorAction.retry,
        requestId: requestId,
        deviceId: doorId,
        retryable: true,
      );
    }
  }
}
