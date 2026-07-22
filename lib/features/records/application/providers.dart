import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/mock_operation_record_repository.dart';
import '../domain/repositories/operation_record_repository.dart';
import 'operation_records_controller.dart';

final operationRecordRepositoryProvider = Provider<OperationRecordRepository>(
  (ref) => MockOperationRecordRepository(),
);

final operationRecordsControllerProvider =
    NotifierProvider<OperationRecordsController, OperationRecordsState>(
      OperationRecordsController.new,
    );
