import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/features/records/application/operation_report_controller.dart';
import 'package:flinx/features/records/domain/entities/operation_record_page_result.dart';
import 'package:flinx/features/records/domain/repositories/operation_record_repository.dart';
import 'package:flinx/features/records/domain/use_cases/report_operation_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reports operations with an independent request ID for each source',
    () async {
      final repository = _RecordingOperationRecordRepository();
      final controller = OperationReportController(
        ReportOperationUseCase(repository: repository),
        _RecordingLogger(),
      );

      for (final source in OperationReportSource.values) {
        await controller.report(
          doorId: '10001',
          action: OperationReportAction.open,
          operationSource: source,
        );
      }

      expect(repository.calls, hasLength(2));
      expect(
        repository.calls.map((call) => call.operationSource),
        OperationReportSource.values,
      );
      expect(
        repository.calls.map((call) => call.doorId),
        everyElement('10001'),
      );
      expect(
        repository.calls.map((call) => call.action),
        everyElement(OperationReportAction.open),
      );
      expect(
        repository.calls.map((call) => call.requestId),
        everyElement(startsWith('operation-report-open-10001-')),
      );
      expect(
        repository.calls.map((call) => call.requestId).toSet(),
        hasLength(2),
      );
    },
  );

  test(
    'silently catches report failures and records the report context',
    () async {
      final repository = _RecordingOperationRecordRepository(
        error: StateError('report failed'),
      );
      final logger = _RecordingLogger();
      final controller = OperationReportController(
        ReportOperationUseCase(repository: repository),
        logger,
      );

      await expectLater(
        controller.report(
          doorId: '10001',
          action: OperationReportAction.ledOffDelayChanged,
          operationSource: OperationReportSource.bluetooth,
        ),
        completes,
      );

      expect(logger.errors, hasLength(1));
      expect(logger.errors.single.message, 'Door operation report failed');
      expect(
        logger.errors.single.requestId,
        startsWith('operation-report-ledOffDelayChanged-10001-'),
      );
      expect(logger.errors.single.context, {
        'doorId': '10001',
        'action': 'LED_OFF_DELAY_CHANGED',
        'operationSource': 'BLUETOOTH',
      });
    },
  );
}

class _RecordingOperationRecordRepository implements OperationRecordRepository {
  _RecordingOperationRecordRepository({this.error});

  final Object? error;
  final List<_ReportCall> calls = <_ReportCall>[];

  @override
  Future<void> reportOperation({
    required String doorId,
    required OperationReportAction action,
    required OperationReportSource operationSource,
    required String requestId,
  }) async {
    calls.add(
      _ReportCall(
        doorId: doorId,
        action: action,
        operationSource: operationSource,
        requestId: requestId,
      ),
    );
    if (error != null) {
      throw error!;
    }
  }

  @override
  Future<OperationRecordPageResult> fetchOperationRecords({
    required String doorId,
    required int page,
    required int pageSize,
    required String requestId,
  }) => throw UnimplementedError();
}

class _ReportCall {
  const _ReportCall({
    required this.doorId,
    required this.action,
    required this.operationSource,
    required this.requestId,
  });

  final String doorId;
  final OperationReportAction action;
  final OperationReportSource operationSource;
  final String requestId;
}

class _RecordingLogger implements AppLogger {
  final List<_LogRecord> errors = <_LogRecord>[];

  @override
  void error(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    errors.add(
      _LogRecord(message: message, requestId: requestId, context: context),
    );
  }

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

class _LogRecord {
  const _LogRecord({
    required this.message,
    required this.requestId,
    required this.context,
  });

  final String message;
  final String? requestId;
  final Map<String, Object?> context;
}
