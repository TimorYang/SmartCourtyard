import 'full_report.dart';

class GeneralEvaluationReport {
  const GeneralEvaluationReport({
    required this.motorName,
    required this.cycleSummary,
    required this.openBalanceEvaluation,
    required this.closeBalanceEvaluation,
    required this.last24HoursRecord,
    required this.last7DaysRecord,
    required this.motorFunctionStatus,
    required this.balancePending,
  });

  final String motorName;
  final FullReportCycleSummary cycleSummary;
  final FullReportBalanceEvaluation openBalanceEvaluation;
  final FullReportBalanceEvaluation closeBalanceEvaluation;
  final FullReportOperationRecord last24HoursRecord;
  final FullReportOperationRecord last7DaysRecord;
  final FullReportMotorFunctionStatus motorFunctionStatus;
  final bool balancePending;
}
