import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/upgrade_check.dart';
import '../../domain/repositories/upgrade_repository.dart';
import '../data_sources/upgrade_progress_local_data_source.dart';
import '../data_sources/upgrade_remote_data_source.dart';
import '../dto/upgrade_dto.dart';

class UpgradeRepositoryImpl implements UpgradeRepository {
  const UpgradeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.logger,
  });

  final UpgradeRemoteDataSource remoteDataSource;
  final UpgradeProgressLocalDataSource localDataSource;
  final AppLogger logger;

  @override
  Future<AppReleaseUpdate> checkAppRelease({required String requestId}) async {
    try {
      final dto = await remoteDataSource.checkAppRelease(requestId: requestId);
      final update = dto.toDomain();
      logger.info(
        'Checked app release.',
        requestId: requestId,
        context: {'action': update.action.name},
      );
      return update;
    } on UpgradeRemoteException catch (error, stackTrace) {
      throw _mapRemoteError(error, requestId, stackTrace);
    } on FormatException catch (error, stackTrace) {
      throw _mapInvalidData(error, requestId, stackTrace);
    }
  }

  @override
  Future<List<FirmwareUpgradeDoor>> fetchFirmwareUpgrades({
    required String requestId,
  }) async {
    try {
      final dtos = await remoteDataSource.fetchFirmwareUpgrades(
        requestId: requestId,
      );
      final doors = dtos.map((dto) => dto.toDomain()).toList(growable: false);
      logger.info(
        'Fetched firmware upgrade targets.',
        requestId: requestId,
        context: {
          'doorCount': doors.length,
          'targetCount': doors.fold<int>(
            0,
            (count, door) => count + door.upgrades.length,
          ),
        },
      );
      return doors;
    } on UpgradeRemoteException catch (error, stackTrace) {
      throw _mapRemoteError(error, requestId, stackTrace);
    } on FormatException catch (error, stackTrace) {
      throw _mapInvalidData(error, requestId, stackTrace);
    }
  }

  @override
  Future<List<FirmwareUpgradeSubmissionResult>> submitFirmwareUpgrades({
    required UpgradeSchedule schedule,
    required List<FirmwareUpgradeTarget> targets,
    required String requestId,
  }) async {
    try {
      final request = FirmwareUpgradeSubmitRequestDto(
        upgradeMode: schedule.mode == UpgradeScheduleMode.immediate
            ? 'IMMEDIATE'
            : 'SCHEDULED',
        scheduledAt: schedule.normalizedScheduledAt
            ?.toUtc()
            .millisecondsSinceEpoch
            .toString(),
        items: targets
            .map(
              (target) => FirmwareUpgradeSubmitItemDto(
                deviceId: target.deviceId,
                firmwareReleaseId: target.firmwareReleaseId,
              ),
            )
            .toList(growable: false),
      );
      final dtos = await remoteDataSource.submitFirmwareUpgrades(
        request: request,
        requestId: requestId,
      );
      final results = dtos.map((dto) => dto.toDomain()).toList(growable: false);
      final rejected = results.where((result) => !result.accepted).toList();
      logger.info(
        'Submitted firmware upgrades.',
        requestId: requestId,
        context: {
          'requestedCount': targets.length,
          'acceptedCount': results.length - rejected.length,
          'rejectedCount': rejected.length,
          'mode': schedule.mode.name,
        },
      );
      for (final result in rejected) {
        logger.warning(
          'Firmware upgrade target was not accepted.',
          requestId: requestId,
          context: {
            'deviceId': result.deviceId,
            'firmwareReleaseId': result.firmwareReleaseId,
            'failureMessage': result.failureMessage == null
                ? null
                : '<redacted>',
          },
        );
      }
      return results;
    } on UpgradeRemoteException catch (error, stackTrace) {
      throw _mapRemoteError(error, requestId, stackTrace);
    } on FormatException catch (error, stackTrace) {
      throw _mapInvalidData(error, requestId, stackTrace);
    }
  }

  @override
  Future<Map<String, int>> readProgresses({required String userId}) {
    return localDataSource.readProgresses(userId: userId);
  }

  @override
  Future<void> replaceProgresses({
    required String userId,
    required Map<String, int> progresses,
  }) {
    return localDataSource.replaceProgresses(
      userId: userId,
      progresses: progresses,
    );
  }

  AppError _mapRemoteError(
    UpgradeRemoteException error,
    String requestId,
    StackTrace stackTrace,
  ) {
    logger.error(
      'Upgrade request failed.',
      requestId: requestId,
      error: error,
      stackTrace: stackTrace,
      context: {'statusCode': error.statusCode, 'kind': error.kind.name},
    );
    if (error.kind == UpgradeRemoteErrorKind.network && error.network != null) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'upgradeCheck.failed',
      businessCode: error.businessFailure?.code,
      businessMessageKey: error.businessFailure?.messageKey,
      userMessage: error.kind == UpgradeRemoteErrorKind.businessFailure
          ? error.businessFailure?.message
          : null,
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }

  AppError _mapInvalidData(
    Object error,
    String requestId,
    StackTrace stackTrace,
  ) {
    logger.error(
      'Upgrade response mapping failed.',
      requestId: requestId,
      error: error,
      stackTrace: stackTrace,
    );
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'upgradeCheck.failed',
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }
}

extension AppReleaseCheckResponseDtoMapper on AppReleaseCheckResponseDto {
  AppReleaseUpdate toDomain() {
    return AppReleaseUpdate(
      action: switch (action) {
        'NONE' => AppReleaseAction.none,
        'OPTIONAL' => AppReleaseAction.optional,
        'FORCE' => AppReleaseAction.force,
        _ => throw const FormatException('Unknown app release action.'),
      },
      targetVersion: targetVersion,
      targetBuildNumber: targetBuildNumber,
      publishedAt: _parseMilliseconds(publishedAt),
      updateUrl: updateUrl == null ? null : Uri.tryParse(updateUrl!),
    );
  }
}

extension FirmwareUpgradeDoorDtoMapper on FirmwareUpgradeDoorDto {
  FirmwareUpgradeDoor toDomain() {
    return FirmwareUpgradeDoor(
      doorId: doorId,
      doorName: doorName,
      upgrades: upgrades
          .map((upgrade) => upgrade.toDomain())
          .toList(growable: false),
    );
  }
}

extension FirmwareUpgradeTargetDtoMapper on FirmwareUpgradeTargetDto {
  FirmwareUpgradeTarget toDomain() {
    return FirmwareUpgradeTarget(
      deviceId: deviceId,
      firmwareReleaseId: firmwareReleaseId,
      serialNumber: serialNumber,
      currentVersion: currentVersion,
      deviceType: deviceType,
      deviceTypeLabel: deviceTypeLabel,
      packageSizeBytes: int.parse(packageSize),
      availableVersion: availableVersion,
      lastFirmwareUpgradedAt: _parseMilliseconds(lastFirmwareUpgradedAt),
      status: switch (status) {
        'AVAILABLE' => FirmwareUpgradeStatus.available,
        'SCHEDULED' => FirmwareUpgradeStatus.scheduled,
        'UPGRADING' => FirmwareUpgradeStatus.upgrading,
        _ => throw const FormatException('Unknown firmware upgrade status.'),
      },
      scheduledAt: _parseMilliseconds(scheduledAt),
      upgradeExpireAt: _parseIsoDateTime(upgradeExpireAt),
    );
  }
}

extension FirmwareUpgradeSubmitResponseDtoMapper
    on FirmwareUpgradeSubmitResponseDto {
  FirmwareUpgradeSubmissionResult toDomain() {
    return FirmwareUpgradeSubmissionResult(
      deviceId: deviceId,
      firmwareReleaseId: firmwareReleaseId,
      accepted: accepted,
      scheduledAt: _parseMilliseconds(scheduledAt),
      upgradeExpireAt: _parseIsoDateTime(upgradeExpireAt),
      failureMessage: failureMessage,
    );
  }
}

DateTime? _parseMilliseconds(String? value) {
  if (value == null) return null;
  final milliseconds = int.tryParse(value);
  if (milliseconds == null) {
    throw const FormatException('Invalid millisecond timestamp.');
  }
  return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
}

DateTime? _parseIsoDateTime(String? value) {
  if (value == null) return null;
  return DateTime.tryParse(value)?.toUtc();
}
