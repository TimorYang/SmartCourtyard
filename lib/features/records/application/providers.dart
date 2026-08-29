import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/providers.dart';
import '../../../core/network/providers.dart';
import '../data/data_sources/operation_record_api.dart';
import '../data/data_sources/operation_record_remote_data_source.dart';
import '../data/repositories/operation_record_repository_impl.dart';
import '../domain/repositories/operation_record_repository.dart';
import '../domain/use_cases/fetch_operation_records_use_case.dart';
import '../domain/use_cases/report_operation_use_case.dart';
import 'operation_report_controller.dart';
import 'operation_records_controller.dart';

final operationRecordApiProvider = Provider<OperationRecordApi>((ref) {
  return OperationRecordApi(ref.watch(dioProvider));
});

final operationRecordRemoteDataSourceProvider =
    Provider<OperationRecordRemoteDataSource>((ref) {
      return OperationRecordRemoteDataSourceImpl(
        api: ref.watch(operationRecordApiProvider),
      );
    });

final operationRecordRepositoryProvider = Provider<OperationRecordRepository>(
  (ref) => OperationRecordRepositoryImpl(
    remoteDataSource: ref.watch(operationRecordRemoteDataSourceProvider),
    logger: ref.watch(appLoggerProvider),
  ),
);

final fetchOperationRecordsUseCaseProvider =
    Provider<FetchOperationRecordsUseCase>((ref) {
      return FetchOperationRecordsUseCase(
        repository: ref.watch(operationRecordRepositoryProvider),
      );
    });

final reportOperationUseCaseProvider = Provider<ReportOperationUseCase>((ref) {
  return ReportOperationUseCase(
    repository: ref.watch(operationRecordRepositoryProvider),
  );
});

final operationReportControllerProvider = Provider<OperationReportController>(
  (ref) => OperationReportController(
    ref.watch(reportOperationUseCaseProvider),
    ref.watch(appLoggerProvider),
  ),
);

final operationRecordsControllerProvider =
    NotifierProvider<OperationRecordsController, OperationRecordsState>(
      OperationRecordsController.new,
    );
