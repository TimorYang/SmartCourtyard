import 'package:dio/dio.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/security_center/data/data_sources/safety_sensors_evaluation_api.dart';
import 'package:flinx/features/security_center/data/data_sources/safety_sensors_evaluation_remote_data_source.dart';
import 'package:flinx/features/security_center/data/dto/safety_sensors_evaluation_dto.dart';
import 'package:flinx/features/security_center/data/repositories/safety_sensors_evaluation_repository_impl.dart';
import 'package:flinx/features/security_center/domain/entities/safety_sensors_evaluation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const response = SafetySensorsEvaluationDto(
    sensorCount: 2,
    normalCount: 1,
    abnormalCount: 1,
    lowBatteryCount: 1,
    wiredSensors: [
      SafetySensorItemDto(sensorCode: 'WIRED_ELECTRONIC_LOCK', status: '4'),
    ],
    wirelessSensors: [
      SafetySensorItemDto(
        sensorCode: 'WIRELESS_PHOTO_BEAM',
        status: '2',
        batteryStatus: '2',
        triggerBuckets: [
          SafetySensorTriggerBucketDto(hour: 9, triggerCount: 21),
        ],
      ),
    ],
  );

  test('DTO parses tolerant numeric fields and serializes sensor buckets', () {
    final dto = SafetySensorsEvaluationDto.fromJson(const {
      'sensorCount': '2',
      'wiredSensors': [
        {'sensorCode': 'WIRED_ELECTRONIC_LOCK', 'status': 4},
      ],
      'wirelessSensors': [
        {
          'sensorCode': 'WIRELESS_PHOTO_BEAM',
          'status': '2',
          'triggerBuckets': [
            {'hour': '9', 'triggerCount': 21, 'abnormal': true},
          ],
        },
      ],
      'futureField': true,
    });

    expect(dto.sensorCount, 2);
    expect(dto.wiredSensors.single.status, '4');
    expect(dto.wirelessSensors.single.triggerBuckets.single.hour, 9);
    expect(dto.toJson()['sensorCount'], 2);
  });

  test(
    'remote data source passes request ID and rejects unsuccessful envelopes',
    () async {
      final api = _FakeApi(
        const ApiEnvelopeDto(code: 200, success: true, data: response),
      );
      final source = SafetySensorsEvaluationRemoteDataSourceImpl(api: api);

      final result = await source.fetchEvaluation(
        doorId: 12,
        requestId: 'safety-12',
      );

      expect(result.sensorCount, 2);
      expect(api.doorId, 12);
      expect(api.options.extra?[NetworkRequestExtras.requestId], 'safety-12');

      final failing = SafetySensorsEvaluationRemoteDataSourceImpl(
        api: _FakeApi(const ApiEnvelopeDto(code: 200, success: false)),
      );
      await expectLater(
        failing.fetchEvaluation(doorId: 12, requestId: 'safety-12'),
        throwsA(isA<SafetySensorsEvaluationRemoteException>()),
      );
    },
  );

  test(
    'repository maps Locked to abnormal and retains hourly trigger data',
    () async {
      final repository = SafetySensorsEvaluationRepositoryImpl(
        remoteDataSource: _FakeRemote(response),
        logger: const _NoopLogger(),
      );

      final evaluation = await repository.fetchEvaluation(
        doorId: '12',
        requestId: 'safety-12',
      );

      expect(
        evaluation.wiredSensorGroup.status,
        SafetySensorGroupStatus.abnormal,
      );
      expect(
        evaluation.wiredSensorGroup.sensors.single.status,
        SafetySensorStatus.locked,
      );
      expect(
        evaluation
            .wirelessSensorGroup
            .sensors
            .single
            .operationPoints
            .single
            .cycles,
        21,
      );
    },
  );
}

class _FakeApi implements SafetySensorsEvaluationApi {
  _FakeApi(this.response);

  final ApiEnvelopeDto<SafetySensorsEvaluationDto> response;
  late int doorId;
  late Options options;

  @override
  Future<ApiEnvelopeDto<SafetySensorsEvaluationDto>> fetchEvaluation(
    int doorId,
    Options options,
  ) async {
    this.doorId = doorId;
    this.options = options;
    return response;
  }
}

class _FakeRemote implements SafetySensorsEvaluationRemoteDataSource {
  const _FakeRemote(this.response);

  final SafetySensorsEvaluationDto response;

  @override
  Future<SafetySensorsEvaluationDto> fetchEvaluation({
    required int doorId,
    required String requestId,
  }) async => response;
}

class _NoopLogger implements AppLogger {
  const _NoopLogger();

  @override
  void error(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}
  @override
  void info(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}
  @override
  void warning(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}
}
