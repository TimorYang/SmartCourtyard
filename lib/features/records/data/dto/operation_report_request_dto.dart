import '../../domain/entities/operation_report.dart';

class OperationReportRequestDto {
  const OperationReportRequestDto({
    required this.action,
    required this.operationSource,
  });

  final OperationReportAction action;
  final OperationReportSource operationSource;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'action': action.wireValue,
    'operationSource': operationSource.wireValue,
  };
}
