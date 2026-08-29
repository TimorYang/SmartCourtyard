import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/security_center_connection_status.dart';
import '../../domain/entities/security_center_overview.dart';
import '../../domain/entities/safety_sensors_evaluation.dart';
import '../dto/security_center_connection_status_dto.dart';
import '../../domain/repositories/security_center_connection_status_repository.dart';
import '../data_sources/security_center_connection_status_remote_data_source.dart';

class SecurityCenterConnectionStatusRepositoryImpl
    implements SecurityCenterConnectionStatusRepository {
  const SecurityCenterConnectionStatusRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final SecurityCenterConnectionStatusRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<SecurityCenterConnectionStatus> fetchConnectionStatus({
    required String doorId,
    required String requestId,
  }) async {
    final parsedDoorId = int.tryParse(doorId.trim());
    if (parsedDoorId == null) {
      throw AppError(
        code: AppErrorCode.unknown,
        messageKey: 'security_center_connection_status_invalid_door_id',
        requestId: requestId,
        deviceId: doorId,
      );
    }
    try {
      final dto = await remoteDataSource.fetchConnectionStatus(
        doorId: parsedDoorId,
        requestId: requestId,
      );
      return SecurityCenterConnectionStatus(
        wifiConnectionStatus: dto.wifiConnectionStatus!,
        sensorEvaluation: _toSensorEvaluation(dto),
      );
    } on SecurityCenterConnectionStatusRemoteException catch (
      error,
      stackTrace
    ) {
      logger.error(
        'Failed to fetch security center connection status',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'errorKind': error.kind.name},
      );
      if (error.kind == SecurityCenterConnectionStatusRemoteErrorKind.network &&
          error.network != null) {
        throw mapNetworkExceptionToAppError(
          error.network!,
          requestId: requestId,
          deviceId: doorId,
        );
      }
      throw AppError(
        code: AppErrorCode.serverError,
        messageKey: 'security_center_connection_status_load_failed',
        businessCode: error.businessFailure?.code,
        businessMessageKey: error.businessFailure?.messageKey,
        userMessage:
            error.kind ==
                SecurityCenterConnectionStatusRemoteErrorKind.businessFailure
            ? error.businessFailure?.message
            : null,
        action: AppErrorAction.retry,
        requestId: requestId,
        deviceId: doorId,
        retryable: true,
      );
    }
  }

  SecuritySensorEvaluation _toSensorEvaluation(
    SecurityCenterConnectionStatusDto dto,
  ) {
    final wiredByCode = _itemsByCode(dto.wiredSensors);
    final wirelessByCode = _itemsByCode(dto.wirelessSensors);
    final wiredSensors = _wiredSlots
        .map((slot) => _toSnapshot(slot, wiredByCode[slot.code]))
        .toList(growable: false);
    final wirelessSensors = _wirelessSlots
        .map((slot) => _toSnapshot(slot, wirelessByCode[slot.code]))
        .toList(growable: false);
    final allSlotsPresent = [
      ..._wiredSlots.map((slot) => wiredByCode.containsKey(slot.code)),
      ..._wirelessSlots.map((slot) => wirelessByCode.containsKey(slot.code)),
    ].every((isPresent) => isPresent);
    final status = !allSlotsPresent
        ? SecurityEvaluationStatus.offline
        : switch (dto.sensorStatus?.trim()) {
            '1' => SecurityEvaluationStatus.normal,
            '2' => SecurityEvaluationStatus.critical,
            _ => SecurityEvaluationStatus.offline,
          };
    return SecuritySensorEvaluation(
      status: status,
      highlightedSensorTypes: const [
        SecuritySensorType.photoBeam,
        SecuritySensorType.eLock,
      ],
      wirelessSensors: wirelessSensors,
      wiredSensors: wiredSensors,
    );
  }

  Map<String, SecurityCenterSensorStatusItemDto> _itemsByCode(
    Iterable<SecurityCenterSensorStatusItemDto> items,
  ) => {
    for (final item in items)
      if (item.sensorCode?.trim().isNotEmpty ?? false)
        item.sensorCode!.trim(): item,
  };

  SecuritySensorSnapshot _toSnapshot(
    _SensorSlot slot,
    SecurityCenterSensorStatusItemDto? item,
  ) => SecuritySensorSnapshot(
    id: slot.code,
    type: slot.type,
    status: switch (item?.status?.trim()) {
      '1' || '3' => SecurityEvaluationStatus.normal,
      '2' || '4' => SecurityEvaluationStatus.critical,
      '0' || null => SecurityEvaluationStatus.offline,
      _ => SecurityEvaluationStatus.offline,
    },
    batteryPercentage: 0,
    hasBattery: slot.hasBattery,
    batteryStatus: switch (item?.batteryStatus?.trim()) {
      '1' => SafetySensorBatteryStatus.normal,
      '2' => SafetySensorBatteryStatus.low,
      _ => SafetySensorBatteryStatus.unknown,
    },
  );
}

class _SensorSlot {
  const _SensorSlot(this.code, this.type, {this.hasBattery = true});

  final String code;
  final SecuritySensorType type;
  final bool hasBattery;
}

const _wiredSlots = [
  _SensorSlot(
    'WIRED_PHOTO_BEAM',
    SecuritySensorType.wiredPhotoBeam,
    hasBattery: false,
  ),
  _SensorSlot(
    'WIRED_ELECTRONIC_LOCK',
    SecuritySensorType.wiredELock,
    hasBattery: false,
  ),
];

const _wirelessSlots = [
  _SensorSlot('WIRELESS_PHOTO_BEAM', SecuritySensorType.photoBeam),
  _SensorSlot('WIRELESS_WICKET_DOOR', SecuritySensorType.doorSensor),
  _SensorSlot('WIRELESS_ELECTRONIC_LOCK', SecuritySensorType.eLock),
  _SensorSlot('WIRELESS_SAFETY_EDGE', SecuritySensorType.safetyEdge),
  _SensorSlot('WIRELESS_SLACK_ROPE', SecuritySensorType.radar),
];
