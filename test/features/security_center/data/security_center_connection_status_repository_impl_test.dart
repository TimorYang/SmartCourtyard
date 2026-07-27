import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/features/security_center/data/data_sources/security_center_connection_status_remote_data_source.dart';
import 'package:flinx/features/security_center/data/dto/security_center_connection_status_dto.dart';
import 'package:flinx/features/security_center/data/repositories/security_center_connection_status_repository_impl.dart';
import 'package:flinx/features/security_center/domain/entities/safety_sensors_evaluation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the sensor fields from the connection-status response', () {
    final dto = SecurityCenterConnectionStatusDto.fromJson(const {
      'wifiConnectionStatus': 2,
      'sensorStatus': 1,
      'wiredSensors': [
        {'sensorCode': 'WIRED_PHOTO_BEAM', 'status': 1},
      ],
      'wirelessSensors': [
        {'sensorCode': 'WIRELESS_PHOTO_BEAM', 'status': 2, 'batteryStatus': 2},
      ],
      'futureField': true,
    });

    expect(dto.wifiConnectionStatus, '2');
    expect(dto.sensorStatus, '1');
    expect(dto.wiredSensors.single.sensorCode, 'WIRED_PHOTO_BEAM');
    expect(dto.wirelessSensors.single.batteryStatus, '2');
  });

  test(
    'maps all fixed sensor slots and slack rope to the radar slot',
    () async {
      final repository = _repository(
        const SecurityCenterConnectionStatusDto(
          wifiConnectionStatus: '2',
          sensorStatus: '2',
          wiredSensors: [
            SecurityCenterSensorStatusItemDto(
              sensorCode: 'WIRED_PHOTO_BEAM',
              status: '1',
            ),
            SecurityCenterSensorStatusItemDto(
              sensorCode: 'WIRED_ELECTRONIC_LOCK',
              status: '3',
            ),
          ],
          wirelessSensors: [
            SecurityCenterSensorStatusItemDto(
              sensorCode: 'WIRELESS_PHOTO_BEAM',
              status: '2',
              batteryStatus: '2',
            ),
            SecurityCenterSensorStatusItemDto(
              sensorCode: 'WIRELESS_WICKET_DOOR',
              status: '1',
              batteryStatus: '1',
            ),
            SecurityCenterSensorStatusItemDto(
              sensorCode: 'WIRELESS_ELECTRONIC_LOCK',
              status: '4',
              batteryStatus: '1',
            ),
            SecurityCenterSensorStatusItemDto(
              sensorCode: 'WIRELESS_SAFETY_EDGE',
              status: '0',
            ),
            SecurityCenterSensorStatusItemDto(
              sensorCode: 'WIRELESS_SLACK_ROPE',
              status: '1',
              batteryStatus: '1',
            ),
          ],
        ),
      );

      final result = await repository.fetchConnectionStatus(
        doorId: '12',
        requestId: 'test-request',
      );

      final evaluation = result.sensorEvaluation;
      expect(evaluation.status.name, 'critical');
      expect(evaluation.wiredSensors.map((item) => item.type.name), [
        'wiredPhotoBeam',
        'wiredELock',
      ]);
      expect(evaluation.wirelessSensors.map((item) => item.type.name), [
        'photoBeam',
        'doorSensor',
        'eLock',
        'safetyEdge',
        'radar',
      ]);
      expect(evaluation.wiredSensors.every((item) => !item.hasBattery), isTrue);
      expect(evaluation.wiredSensors[1].status.name, 'normal');
      expect(evaluation.wirelessSensors[2].status.name, 'critical');
      expect(evaluation.highlightedSensorTypes.map((item) => item.name), [
        'photoBeam',
        'eLock',
      ]);
      expect(
        evaluation.wirelessSensors.first.batteryStatus,
        SafetySensorBatteryStatus.low,
      );
      expect(evaluation.wirelessSensors[3].status.name, 'offline');
    },
  );

  test('marks every missing sensor slot as offline', () async {
    final repository = _repository(
      const SecurityCenterConnectionStatusDto(
        wifiConnectionStatus: '2',
        sensorStatus: '1',
      ),
    );

    final result = await repository.fetchConnectionStatus(
      doorId: '12',
      requestId: 'test-request',
    );

    expect(result.sensorEvaluation.status.name, 'offline');
    expect(
      [
        ...result.sensorEvaluation.wiredSensors,
        ...result.sensorEvaluation.wirelessSensors,
      ].every((sensor) => sensor.status.name == 'offline'),
      isTrue,
    );
  });
}

SecurityCenterConnectionStatusRepositoryImpl _repository(
  SecurityCenterConnectionStatusDto response,
) => SecurityCenterConnectionStatusRepositoryImpl(
  remoteDataSource: _FakeRemoteDataSource(response),
  logger: const _NoopLogger(),
);

class _FakeRemoteDataSource
    implements SecurityCenterConnectionStatusRemoteDataSource {
  const _FakeRemoteDataSource(this.response);

  final SecurityCenterConnectionStatusDto response;

  @override
  Future<SecurityCenterConnectionStatusDto> fetchConnectionStatus({
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
