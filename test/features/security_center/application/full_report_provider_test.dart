import 'package:flinx/features/security_center/application/providers.dart';
import 'package:flinx/features/security_center/domain/entities/safety_sensors_evaluation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('full report mock contains data for every report section', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final report = container.read(fullReportProvider('mock-device'));

    expect(report.deviceId, 'mock-device');
    expect(report.motorName, isNotEmpty);
    expect(report.serialNumber, isNotEmpty);
    expect(report.cycleSummary.doorName, isNotEmpty);
    expect(report.openBalanceEvaluation.segments, isEmpty);
    expect(report.closeBalanceEvaluation.segments, isEmpty);
    expect(report.last24HoursRecord.points, isNotEmpty);
    expect(report.last7DaysRecord.points, isNotEmpty);
    expect(report.motorFunctionStatus.autoCloseSeconds, greaterThan(0));
    expect(report.wiredSensorDiagnosis.sensors, isNotEmpty);
    expect(report.wirelessSensorDiagnosis.sensors, isNotEmpty);
    expect(report.safetySuggestions, isNotEmpty);
  });

  test('safety sensors evaluation mock contains page display data', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final evaluation = container.read(
      safetySensorsEvaluationProvider('mock-device'),
    );

    expect(evaluation.deviceId, 'mock-device');
    expect(evaluation.totalSensorCount, greaterThan(0));
    expect(evaluation.fineSensorCount, greaterThanOrEqualTo(0));
    expect(evaluation.abnormalSensorCount, greaterThan(0));
    expect(evaluation.lowPowerSensorCount, greaterThan(0));
    expect(evaluation.wiredSensorGroup.sensors, isNotEmpty);
    expect(evaluation.wirelessSensorGroup.sensors, isNotEmpty);
    expect(
      evaluation.wirelessSensorGroup.sensors,
      contains(
        isA<SafetySensor>()
            .having(
              (sensor) => sensor.batteryStatus,
              'batteryStatus',
              SafetySensorBatteryStatus.low,
            )
            .having(
              (sensor) => sensor.batteryPercentage,
              'batteryPercentage',
              lessThan(100),
            )
            .having(
              (sensor) => sensor.operationPoints,
              'operationPoints',
              isNotEmpty,
            ),
      ),
    );
  });
}
