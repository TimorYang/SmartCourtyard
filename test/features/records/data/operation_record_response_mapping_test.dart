import 'package:flinx/features/records/data/dto/operation_record_response_dto.dart';
import 'package:flinx/features/records/data/repositories/operation_record_repository_impl.dart';
import 'package:flinx/features/records/domain/entities/operation_record.dart';
import 'package:flinx/features/records/domain/entities/operation_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every supported operation record action', () {
    const expectedActions = <OperationReportAction, OperationRecordAction>{
      OperationReportAction.open: OperationRecordAction.open,
      OperationReportAction.close: OperationRecordAction.close,
      OperationReportAction.stop: OperationRecordAction.stop,
      OperationReportAction.partialOpen: OperationRecordAction.partialOpen,
      OperationReportAction.autoCloseToggle:
          OperationRecordAction.autoCloseToggle,
      OperationReportAction.ledOn: OperationRecordAction.ledOn,
      OperationReportAction.ledOff: OperationRecordAction.ledOff,
      OperationReportAction.ledOffDelayChanged:
          OperationRecordAction.ledOffDelayChanged,
      OperationReportAction.partialOpenChanged:
          OperationRecordAction.partialOpenChanged,
      OperationReportAction.autoCloseDelayChanged:
          OperationRecordAction.autoCloseDelayChanged,
      OperationReportAction.doorOpenReminderToggle:
          OperationRecordAction.doorOpenReminderToggle,
      OperationReportAction.doorOpenReminderDelayChanged:
          OperationRecordAction.doorOpenReminderDelayChanged,
    };

    for (final entry in expectedActions.entries) {
      final record = OperationRecordResponseDto(
        action: entry.key.wireValue,
      ).toDomain();

      expect(record.action, entry.value, reason: entry.key.wireValue);
    }
  });

  test('normalizes action values and preserves the unknown fallback', () {
    expect(
      const OperationRecordResponseDto(action: ' led_on ').toDomain().action,
      OperationRecordAction.ledOn,
    );
    expect(
      const OperationRecordResponseDto(
        action: 'FUTURE_ACTION',
      ).toDomain().action,
      OperationRecordAction.unknown,
    );
    expect(
      const OperationRecordResponseDto().toDomain().action,
      OperationRecordAction.unknown,
    );
  });
}
