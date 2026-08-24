import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/features/security_center/data/data_sources/general_evaluation_remote_data_source.dart';
import 'package:flinx/features/security_center/data/dto/general_evaluation_dtos.dart';
import 'package:flinx/features/security_center/data/repositories/general_evaluation_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'maps hourly and daily operation buckets to real chart labels',
    () async {
      final remote = _FakeRemoteDataSource();
      final repository = GeneralEvaluationRepositoryImpl(
        remote: remote,
        logger: const _NoopLogger(),
      );

      final report = await repository.fetch(
        doorId: '10',
        assessmentRequestId: 'assessment-id',
        requestId: 'page-request-id',
      );

      expect(report.last24HoursRecord.points.single.axisLabel, '03');
      expect(report.last24HoursRecord.points.single.cycles, 2);
      expect(report.last7DaysRecord.points.single.axisLabel, 'Wed');
      expect(report.last7DaysRecord.points.single.cycles, 4);
      expect(remote.balanceCalls, 1);
    },
  );

  test('keeps missing or invalid operation time values non-fatal', () async {
    final repository = GeneralEvaluationRepositoryImpl(
      remote: _FakeRemoteDataSource(
        today: const OperationStatisticsDto(
          buckets: [OperationBucketDto(operationCycles: '1')],
        ),
        week: const OperationStatisticsDto(
          buckets: [
            OperationBucketDto(date: 'not-a-date', operationCycles: '2'),
          ],
        ),
      ),
      logger: const _NoopLogger(),
    );

    final report = await repository.fetch(
      doorId: '10',
      assessmentRequestId: 'assessment-id',
      requestId: 'page-request-id',
    );

    expect(report.last24HoursRecord.points.single.axisLabel, isEmpty);
    expect(report.last7DaysRecord.points.single.axisLabel, isEmpty);
  });

  test(
    'maps a millisecond date timestamp to an English weekday label',
    () async {
      final repository = GeneralEvaluationRepositoryImpl(
        remote: _FakeRemoteDataSource(
          week: const OperationStatisticsDto(
            buckets: [
              OperationBucketDto(date: '1784736000000', operationCycles: '4'),
            ],
          ),
        ),
        logger: const _NoopLogger(),
      );

      final report = await repository.fetch(
        doorId: '10',
        assessmentRequestId: 'assessment-id',
        requestId: 'page-request-id',
      );

      expect(report.last7DaysRecord.points.single.axisLabel, 'Thu');
    },
  );

  test(
    'skips balance when no server assessment request ID is available',
    () async {
      final remote = _FakeRemoteDataSource();
      final repository = GeneralEvaluationRepositoryImpl(
        remote: remote,
        logger: const _NoopLogger(),
      );

      final report = await repository.fetch(
        doorId: '10',
        requestId: 'page-request-id',
      );

      expect(remote.balanceCalls, 0);
      expect(report.balancePending, isTrue);
      expect(report.last24HoursRecord.points, isNotEmpty);
      expect(report.last7DaysRecord.points, isNotEmpty);
    },
  );

  test('operation bucket DTO accepts numeric and string integer fields', () {
    final dto = OperationBucketDto.fromJson(const {
      'hour': 3,
      'date': 1784736000000,
      'operationCycles': '2',
      'abnormal': false,
    });

    expect(dto.hour, '3');
    expect(dto.date, '1784736000000');
    expect(dto.operationCycles, '2');
  });

  test(
    'maps non-empty safety advice from the general evaluation response',
    () async {
      final repository = GeneralEvaluationRepositoryImpl(
        remote: _FakeRemoteDataSource(
          general: const GeneralEvaluationResponseDto(
            safetyAdvice: [' Advice one ', '', 'Advice two'],
          ),
        ),
        logger: const _NoopLogger(),
      );

      final report = await repository.fetch(
        doorId: '10',
        assessmentRequestId: 'assessment-id',
        requestId: 'page-request-id',
      );

      expect(report.safetyAdvice, ['Advice one', 'Advice two']);
    },
  );

  test('parses safety advice from the general evaluation response', () {
    final dto = GeneralEvaluationResponseDto.fromJson(const {
      'safetyAdvice': [
        '1. The photo eye sensor battery is low. Replace the battery promptly.',
      ],
    });

    expect(dto.safetyAdvice, [
      '1. The photo eye sensor battery is low. Replace the battery promptly.',
    ]);
  });

  test('uses abnormal fields for frequent-operation status', () async {
    final repository = GeneralEvaluationRepositoryImpl(
      remote: _FakeRemoteDataSource(
        today: const OperationStatisticsDto(
          abnormal: true,
          buckets: [
            OperationBucketDto(
              hour: '8',
              operationCycles: '20',
              abnormal: false,
            ),
            OperationBucketDto(
              hour: '9',
              operationCycles: '21',
              abnormal: true,
            ),
          ],
        ),
        week: const OperationStatisticsDto(
          abnormal: true,
          buckets: [
            OperationBucketDto(
              date: '2026-07-22',
              operationCycles: '99',
              abnormal: true,
            ),
          ],
        ),
      ),
      logger: const _NoopLogger(),
    );

    final report = await repository.fetch(
      doorId: '10',
      assessmentRequestId: 'assessment-id',
      requestId: 'page-request-id',
    );

    expect(
      report.last24HoursRecord.points.map((point) => point.isFrequentOperation),
      [false, true],
    );
    expect(report.last24HoursRecord.hasFrequentOperationAlert, isTrue);
    expect(report.last7DaysRecord.points.single.isFrequentOperation, isTrue);
    expect(report.last7DaysRecord.hasFrequentOperationAlert, isTrue);
  });

  test('maps motor function units for numeric display values', () async {
    final repository = GeneralEvaluationRepositoryImpl(
      remote: _FakeRemoteDataSource(
        general: const GeneralEvaluationResponseDto(
          motorFunctions: [
            MotorFunctionItemDto(settingCode: 2, currentValue: 45, unit: 'sec'),
            MotorFunctionItemDto(
              settingCode: 0,
              currentValue: 3,
              unit: 'minutes',
            ),
            MotorFunctionItemDto(settingCode: 1, currentValue: 5, unit: 'mm'),
            MotorFunctionItemDto(settingCode: 8, currentValue: 1, unit: 'cm'),
          ],
        ),
      ),
      logger: const _NoopLogger(),
    );

    final report = await repository.fetch(
      doorId: '10',
      assessmentRequestId: 'assessment-id',
      requestId: 'page-request-id',
    );

    final status = report.motorFunctionStatus;
    expect(status.autoCloseUnit, 'sec');
    expect(status.ledOffDelayUnit, 'minutes');
    expect(status.partialOpenUnit, 'mm');
    expect(status.ignoreObstructionHeightUnit, 'cm');
  });

  test(
    'maps opening and closing balance segments with server labels',
    () async {
      final repository = GeneralEvaluationRepositoryImpl(
        remote: _FakeRemoteDataSource(
          balance: const BalanceResponseDto(
            hasOverloadOrOvercurrent: true,
            openingSegments: [
              BalanceEvaluationSegmentDto(
                startPercent: 0,
                endPercent: 20,
                status: 1,
                statusLabel: 'Normal',
              ),
              BalanceEvaluationSegmentDto(
                startPercent: 80,
                endPercent: 100,
                status: 2,
                statusLabel: 'Blocked',
              ),
            ],
            closingSegments: [
              BalanceEvaluationSegmentDto(status: 3, statusLabel: 'Overload'),
            ],
          ),
        ),
        logger: const _NoopLogger(),
      );

      final report = await repository.fetch(
        doorId: '10',
        assessmentRequestId: 'assessment-id',
        requestId: 'page-request-id',
      );

      expect(report.openBalanceEvaluation.segments, hasLength(2));
      expect(report.openBalanceEvaluation.hasOverloadOrOvercurrent, isTrue);
      expect(report.openBalanceEvaluation.segments[0].isNormal, isTrue);
      expect(report.openBalanceEvaluation.segments[0].startPercent, 0);
      expect(report.openBalanceEvaluation.segments[0].endPercent, 20);
      expect(report.openBalanceEvaluation.segments[0].statusLabel, 'Normal');
      expect(report.openBalanceEvaluation.segments[1].isNormal, isFalse);
      expect(report.openBalanceEvaluation.segments[1].statusLabel, 'Blocked');
      expect(report.closeBalanceEvaluation.segments.single.isNormal, isFalse);
      expect(
        report.closeBalanceEvaluation.segments.single.statusLabel,
        'Overload',
      );
    },
  );
}

class _FakeRemoteDataSource implements GeneralEvaluationRemoteDataSource {
  _FakeRemoteDataSource({
    OperationStatisticsDto? today,
    OperationStatisticsDto? week,
    GeneralEvaluationResponseDto? general,
    BalanceResponseDto? balance,
  }) : _today =
           today ??
           const OperationStatisticsDto(
             buckets: [OperationBucketDto(hour: '3', operationCycles: '2')],
           ),
       _week =
           week ??
           const OperationStatisticsDto(
             buckets: [
               OperationBucketDto(date: '2026-07-22', operationCycles: '4'),
             ],
           ),
       _general = general ?? const GeneralEvaluationResponseDto(),
       _balance = balance ?? const BalanceResponseDto();

  final OperationStatisticsDto _today;
  final OperationStatisticsDto _week;
  final GeneralEvaluationResponseDto _general;
  final BalanceResponseDto _balance;
  var balanceCalls = 0;

  @override
  Future<BalanceResponseDto> balance({
    required int doorId,
    required String assessmentRequestId,
    required String requestId,
  }) async {
    balanceCalls += 1;
    return _balance;
  }

  @override
  Future<GeneralEvaluationResponseDto> general({
    required int doorId,
    required String requestId,
  }) async => _general;

  @override
  Future<OperationStatisticsDto> operations({
    required int doorId,
    required int range,
    required String requestId,
  }) async => range == 0 ? _today : _week;
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
