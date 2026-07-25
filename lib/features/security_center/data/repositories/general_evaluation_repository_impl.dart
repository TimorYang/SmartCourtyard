import 'package:intl/intl.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/full_report.dart';
import '../../domain/entities/general_evaluation_report.dart';
import '../../domain/repositories/general_evaluation_repository.dart';
import '../data_sources/general_evaluation_remote_data_source.dart';
import '../dto/general_evaluation_dtos.dart';

class GeneralEvaluationRepositoryImpl implements GeneralEvaluationRepository {
  const GeneralEvaluationRepositoryImpl({
    required this.remote,
    required this.logger,
  });
  final GeneralEvaluationRemoteDataSource remote;
  final AppLogger logger;
  @override
  Future<GeneralEvaluationReport> fetch({
    required String doorId,
    String? assessmentRequestId,
    required String requestId,
  }) async {
    final id = int.tryParse(doorId);
    if (id == null) {
      throw AppError(
        code: AppErrorCode.unknown,
        messageKey: 'general_evaluation_invalid_door',
        requestId: requestId,
      );
    }
    try {
      // Start every request before awaiting so the four reads remain parallel,
      // while preserving each response's concrete type for the mapping below.
      final generalFuture = remote.general(doorId: id, requestId: requestId);
      final hasBalanceRequestId =
          assessmentRequestId != null && assessmentRequestId.isNotEmpty;
      final balanceFuture = hasBalanceRequestId
          ? remote.balance(
              doorId: id,
              assessmentRequestId: assessmentRequestId,
              requestId: requestId,
            )
          : null;
      final todayFuture = remote.operations(
        doorId: id,
        range: 0,
        requestId: requestId,
      );
      final weekFuture = remote.operations(
        doorId: id,
        range: 1,
        requestId: requestId,
      );
      final pendingRequests = <Future<Object>>[
        generalFuture,
        todayFuture,
        weekFuture,
      ];
      if (balanceFuture != null) {
        pendingRequests.insert(1, balanceFuture);
      }
      final results = await Future.wait(pendingRequests);
      final g = results[0] as GeneralEvaluationResponseDto;
      final hasBalance = balanceFuture != null;
      final b = hasBalance
          ? results[1] as BalanceResponseDto
          : const BalanceResponseDto();
      final today = results[hasBalance ? 2 : 1] as OperationStatisticsDto;
      final week = results[hasBalance ? 3 : 2] as OperationStatisticsDto;
      final funcs = {for (final f in g.motorFunctions) f.settingCode: f};
      int valueFor(int settingCode) => funcs[settingCode]?.currentValue ?? 0;
      String? unitFor(int settingCode) {
        final unit = funcs[settingCode]?.unit?.trim();
        return unit == null || unit.isEmpty ? null : unit;
      }

      FullReportBalanceEvaluation map(
        List<BalanceEvaluationSegmentDto> segments,
      ) {
        return FullReportBalanceEvaluation(
          indicatorPercentage: 50,
          hasOverloadOrOvercurrent: b.hasOverloadOrOvercurrent ?? false,
          segments: segments
              .map(
                (segment) => FullReportBalanceSegment(
                  startPercent: segment.startPercent,
                  endPercent: segment.endPercent,
                  status: segment.status,
                  statusLabel: segment.statusLabel,
                ),
              )
              .toList(),
        );
      }

      FullReportOperationRecord operationRecord(
        OperationStatisticsDto statistics, {
        required bool isHourly,
      }) {
        final points = statistics.buckets.map<FullReportOperationCyclePoint>((
          bucket,
        ) {
          final cycles = int.tryParse(bucket.operationCycles ?? '') ?? 0;
          return FullReportOperationCyclePoint(
            occurredAt: isHourly
                ? _hourDate(bucket.hour)
                : _dateValue(bucket.date),
            axisLabel: isHourly
                ? _hourLabel(bucket.hour)
                : _dateLabel(bucket.date),
            cycles: cycles,
            isFrequentOperation: bucket.abnormal,
          );
        }).toList();
        return FullReportOperationRecord(
          points: points,
          hasFrequentOperationAlert: points.any(
            (point) => point.isFrequentOperation,
          ),
        );
      }

      return GeneralEvaluationReport(
        motorName: g.device?.doorName ?? '',
        cycleSummary: FullReportCycleSummary(
          doorName: g.device?.doorName ?? '',
          operatedCycles: g.device?.operatedCycles ?? 0,
          remainingCycles: g.device?.remainingCycles ?? 0,
          needsMaintenance: g.device?.maintenanceRecommended ?? false,
        ),
        openBalanceEvaluation: map(b.openingSegments),
        closeBalanceEvaluation: map(b.closingSegments),
        last24HoursRecord: operationRecord(today, isHourly: true),
        last7DaysRecord: operationRecord(week, isHourly: false),
        motorFunctionStatus: FullReportMotorFunctionStatus(
          openingForceLevel: valueFor(5),
          closingForceLevel: valueFor(6),
          autoCloseSeconds: valueFor(2),
          autoCloseCondition: valueFor(7) != 0
              ? FullReportAutoCloseCondition.anyPosition
              : FullReportAutoCloseCondition.topPosition,
          ledOffDelayMinutes: valueFor(0),
          partialOpenCentimeters: valueFor(1),
          ignoreObstructionHeightCentimeters: valueFor(8),
          photoBeamEnabled: valueFor(9) != 0,
          communityModeEnabled: valueFor(10) != 0,
          wiredELockEnabled: valueFor(11) != 0,
          autoCloseUnit: unitFor(2),
          ledOffDelayUnit: unitFor(0),
          partialOpenUnit: unitFor(1),
          ignoreObstructionHeightUnit: unitFor(8),
        ),
        balancePending: !hasBalanceRequestId,
      );
    } on GeneralEvaluationRemoteException catch (e, s) {
      logger.error(
        'Failed to load general evaluation',
        requestId: requestId,
        error: e,
        stackTrace: s,
        context: {'doorId': doorId},
      );
      throw AppError(
        code: e.kind == GeneralEvaluationRemoteErrorKind.network
            ? AppErrorCode.networkUnavailable
            : AppErrorCode.serverError,
        messageKey: 'general_evaluation_load_failed',
        requestId: requestId,
        retryable: true,
      );
    }
  }

  DateTime _hourDate(String? hour) {
    final value = int.tryParse(hour ?? '');
    return DateTime(
      1970,
      1,
      1,
      value != null && value >= 0 && value <= 23 ? value : 0,
    );
  }

  String _hourLabel(String? hour) {
    final value = int.tryParse(hour ?? '');
    return value != null && value >= 0 && value <= 23
        ? value.toString().padLeft(2, '0')
        : '';
  }

  DateTime _dateValue(String? value) {
    return _parseDate(value) ?? DateTime(1970);
  }

  DateTime? _parseDate(String? value) {
    final timestamp = int.tryParse(value ?? '');
    if (timestamp != null) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
      } on ArgumentError {
        return null;
      }
    }
    return DateTime.tryParse(value ?? '')?.toLocal();
  }

  String _dateLabel(String? value) {
    final date = _parseDate(value);
    if (date == null) return '';
    return DateFormat('EEE', 'en_US').format(date);
  }
}
