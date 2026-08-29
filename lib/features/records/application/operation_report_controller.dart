import '../../../core/logging/app_logger.dart';
import '../domain/entities/operation_report.dart';
import '../domain/use_cases/report_operation_use_case.dart';

class OperationReportController {
  OperationReportController(this._reportOperation, this._logger);

  final ReportOperationUseCase _reportOperation;
  final AppLogger _logger;
  int _requestCounter = 0;

  Future<void> report({
    required String doorId,
    required OperationReportAction action,
    required OperationReportSource operationSource,
  }) async {
    final requestId = _nextRequestId(doorId, action);
    try {
      await _reportOperation(
        doorId: doorId,
        action: action,
        operationSource: operationSource,
        requestId: requestId,
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Door operation report failed',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'doorId': doorId,
          'action': action.wireValue,
          'operationSource': operationSource.wireValue,
        },
      );
    }
  }

  String _nextRequestId(String doorId, OperationReportAction action) {
    _requestCounter += 1;
    return 'operation-report-${action.name}-$doorId-'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}-$_requestCounter';
  }
}
