import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/safety_sensors_evaluation.dart';
import '../../domain/repositories/safety_sensors_evaluation_repository.dart';
import '../data_sources/safety_sensors_evaluation_remote_data_source.dart';
import '../dto/safety_sensors_evaluation_dto.dart';

class SafetySensorsEvaluationRepositoryImpl
    implements SafetySensorsEvaluationRepository {
  const SafetySensorsEvaluationRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final SafetySensorsEvaluationRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<SafetySensorsEvaluation> fetchEvaluation({
    required String doorId,
    required String requestId,
  }) async {
    final parsedDoorId = int.tryParse(doorId.trim());
    if (parsedDoorId == null) {
      throw AppError(
        code: AppErrorCode.unknown,
        messageKey: 'safety_sensors_invalid_door_id',
        requestId: requestId,
        deviceId: doorId,
      );
    }
    try {
      final dto = await remoteDataSource.fetchEvaluation(
        doorId: parsedDoorId,
        requestId: requestId,
      );
      return SafetySensorsEvaluation(
        deviceId: doorId,
        totalSensorCount: dto.sensorCount ?? 0,
        fineSensorCount: dto.normalCount ?? 0,
        abnormalSensorCount: dto.abnormalCount ?? 0,
        lowPowerSensorCount: dto.lowBatteryCount ?? 0,
        statisticsStartAt: _date(dto.statisticsStartTime),
        statisticsEndAt: _date(dto.statisticsEndTime),
        wiredSensorGroup: _group(dto.wiredSensors),
        wirelessSensorGroup: _group(dto.wirelessSensors),
      );
    } on SafetySensorsEvaluationRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to fetch safety sensors evaluation',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'errorKind': error.kind.name},
      );
      throw AppError(
        code: error.kind == SafetySensorsEvaluationRemoteErrorKind.network
            ? AppErrorCode.networkUnavailable
            : AppErrorCode.serverError,
        messageKey: error.kind == SafetySensorsEvaluationRemoteErrorKind.network
            ? 'safety_sensors_network_unavailable'
            : 'safety_sensors_invalid_response',
        action: AppErrorAction.retry,
        requestId: requestId,
        deviceId: doorId,
        retryable: true,
      );
    }
  }

  SafetySensorGroup _group(List<SafetySensorItemDto> sensors) {
    final mapped = sensors
        .where((sensor) => sensor.sensorCode?.trim().isNotEmpty ?? false)
        .map(_sensor)
        .toList(growable: false);
    if (mapped.isEmpty) {
      return const SafetySensorGroup(
        status: SafetySensorGroupStatus.offline,
        sensors: [],
      );
    }
    final hasAbnormalSensor = mapped.any(
      (sensor) =>
          sensor.status != SafetySensorStatus.notTriggered &&
          sensor.status != SafetySensorStatus.unlocked,
    );
    return SafetySensorGroup(
      status: hasAbnormalSensor
          ? SafetySensorGroupStatus.abnormal
          : SafetySensorGroupStatus.normal,
      sensors: mapped,
    );
  }

  SafetySensor _sensor(SafetySensorItemDto dto) => SafetySensor(
    id: dto.sensorCode!.trim(),
    sensorCode: dto.sensorCode!.trim(),
    status: switch (dto.status?.trim()) {
      '0' => SafetySensorStatus.disconnected,
      '2' => SafetySensorStatus.triggered,
      '3' => SafetySensorStatus.unlocked,
      '4' => SafetySensorStatus.locked,
      _ => SafetySensorStatus.notTriggered,
    },
    batteryStatus: switch (dto.batteryStatus?.trim()) {
      '1' => SafetySensorBatteryStatus.normal,
      '2' => SafetySensorBatteryStatus.low,
      _ => SafetySensorBatteryStatus.unknown,
    },
    operationPoints: dto.triggerBuckets
        .where(
          (bucket) => (bucket.hour ?? -1) >= 0 && (bucket.hour ?? 24) <= 23,
        )
        .map(
          (bucket) => SafetySensorOperationPoint(
            occurredAt: DateTime(1970, 1, 1, bucket.hour!),
            cycles: bucket.triggerCount ?? 0,
            isAbnormal: bucket.abnormal ?? false,
          ),
        )
        .toList(growable: false),
  );

  DateTime? _date(int? milliseconds) => milliseconds == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
}
