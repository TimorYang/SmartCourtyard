import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/api_business_failure.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/core/network/network_exception.dart';
import 'package:flinx/features/records/data/data_sources/operation_record_api.dart';
import 'package:flinx/features/records/data/data_sources/operation_record_remote_data_source.dart';
import 'package:flinx/features/records/data/dto/operation_record_response_dto.dart';
import 'package:flinx/features/records/data/dto/operation_report_request_dto.dart';
import 'package:flinx/features/records/data/repositories/operation_record_repository_impl.dart';
import 'package:flinx/features/records/domain/entities/operation_report.dart';
import 'package:flinx/features/records/domain/repositories/operation_record_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes every operation report action and source', () {
    for (final action in OperationReportAction.values) {
      for (final source in OperationReportSource.values) {
        expect(
          OperationReportRequestDto(
            action: action,
            operationSource: source,
          ).toJson(),
          {'action': action.wireValue, 'operationSource': source.wireValue},
        );
      }
    }
  });

  test('generated API uses the report path, body, and request ID', () async {
    final adapter = _CapturingHttpClientAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/force-door/'))
      ..httpClientAdapter = adapter;
    final api = OperationRecordApi(dio);

    await api.reportOperation(
      10001,
      const OperationReportRequestDto(
        action: OperationReportAction.open,
        operationSource: OperationReportSource.bluetooth,
      ),
      Options(extra: {NetworkRequestExtras.requestId: 'report-api-1'}),
    );

    expect(adapter.requestOptions.method, 'POST');
    expect(
      adapter.requestOptions.uri.path,
      '/force-door/app/doors/10001/operation-records',
    );
    expect(adapter.requestOptions.data, {
      'action': 'OPEN',
      'operationSource': 'BLUETOOTH',
    });
    expect(
      adapter.requestOptions.extra[NetworkRequestExtras.requestId],
      'report-api-1',
    );
  });

  test(
    'remote data source accepts code zero and code 200 success responses',
    () async {
      for (final code in [0, 200]) {
        final api = _FakeOperationRecordApi(
          reportResponse: ApiEnvelopeDto<bool>(
            code: code,
            success: true,
            data: true,
          ),
        );
        final dataSource = OperationRecordRemoteDataSourceImpl(api: api);

        await dataSource.reportOperation(
          doorId: 10001,
          body: const OperationReportRequestDto(
            action: OperationReportAction.close,
            operationSource: OperationReportSource.app,
          ),
          requestId: 'report-$code',
        );

        expect(api.reportedDoorId, 10001);
        expect(api.reportedBody?.toJson(), {
          'action': 'CLOSE',
          'operationSource': 'APP',
        });
        expect(
          api.reportedOptions?.extra?[NetworkRequestExtras.requestId],
          'report-$code',
        );
      }
    },
  );

  test('remote data source rejects an unsuccessful envelope', () async {
    final dataSource = OperationRecordRemoteDataSourceImpl(
      api: _FakeOperationRecordApi(
        reportResponse: const ApiEnvelopeDto<bool>(code: 200, success: false),
      ),
    );

    await expectLater(
      dataSource.reportOperation(
        doorId: 10001,
        body: const OperationReportRequestDto(
          action: OperationReportAction.stop,
          operationSource: OperationReportSource.bluetooth,
        ),
        requestId: 'report-unsuccessful',
      ),
      throwsA(
        isA<OperationRecordRemoteException>().having(
          (error) => error.kind,
          'kind',
          OperationRecordRemoteErrorKind.businessFailure,
        ),
      ),
    );
  });

  test('remote data source rejects false and null data', () async {
    for (final response in [
      const ApiEnvelopeDto<bool>(code: 200, success: true, data: false),
      const ApiEnvelopeDto<bool>(code: 200, success: true),
    ]) {
      final dataSource = OperationRecordRemoteDataSourceImpl(
        api: _FakeOperationRecordApi(reportResponse: response),
      );

      await expectLater(
        dataSource.reportOperation(
          doorId: 10001,
          body: const OperationReportRequestDto(
            action: OperationReportAction.ledOn,
            operationSource: OperationReportSource.app,
          ),
          requestId: 'report-invalid-data',
        ),
        throwsA(
          isA<OperationRecordRemoteException>().having(
            (error) => error.kind,
            'kind',
            OperationRecordRemoteErrorKind.invalidResponse,
          ),
        ),
      );
    }
  });

  test(
    'remote data source turns malformed responses into invalid response errors',
    () async {
      final dataSource = OperationRecordRemoteDataSourceImpl(
        api: _FakeOperationRecordApi(
          reportError: const FormatException('bad body'),
        ),
      );

      await expectLater(
        dataSource.reportOperation(
          doorId: 10001,
          body: const OperationReportRequestDto(
            action: OperationReportAction.ledOff,
            operationSource: OperationReportSource.bluetooth,
          ),
          requestId: 'report-malformed',
        ),
        throwsA(
          isA<OperationRecordRemoteException>().having(
            (error) => error.kind,
            'kind',
            OperationRecordRemoteErrorKind.invalidResponse,
          ),
        ),
      );
    },
  );

  test('remote data source maps Dio network errors', () async {
    final dataSource = OperationRecordRemoteDataSourceImpl(
      api: _FakeOperationRecordApi(
        reportError: DioException(
          requestOptions: RequestOptions(path: 'operation-records'),
          type: DioExceptionType.connectionError,
        ),
      ),
    );

    await expectLater(
      dataSource.reportOperation(
        doorId: 10001,
        body: const OperationReportRequestDto(
          action: OperationReportAction.open,
          operationSource: OperationReportSource.app,
        ),
        requestId: 'report-network-error',
      ),
      throwsA(
        isA<OperationRecordRemoteException>()
            .having(
              (error) => error.kind,
              'kind',
              OperationRecordRemoteErrorKind.network,
            )
            .having(
              (error) => error.network?.kind,
              'network kind',
              NetworkErrorKind.connection,
            ),
      ),
    );
  });

  test(
    'repository rejects an invalid door ID before making a request',
    () async {
      final remoteDataSource = _FakeOperationRecordRemoteDataSource();
      final repository = OperationRecordRepositoryImpl(
        remoteDataSource: remoteDataSource,
        logger: _RecordingLogger(),
      );

      await expectLater(
        repository.reportOperation(
          doorId: 'not-a-number',
          action: OperationReportAction.open,
          operationSource: OperationReportSource.bluetooth,
          requestId: 'report-invalid-door',
        ),
        throwsA(
          isA<AppError>()
              .having((error) => error.code, 'code', AppErrorCode.unknown)
              .having(
                (error) => error.messageKey,
                'message key',
                'operation_report_invalid_door_id',
              ),
        ),
      );
      expect(remoteDataSource.reportedDoorId, isNull);
    },
  );

  test(
    'repository maps report failures to AppError and preserves request metadata',
    () async {
      final remoteDataSource = _FakeOperationRecordRemoteDataSource(
        error: OperationRecordRemoteException.businessFailure(
          ApiBusinessFailure(code: 409, message: 'Rejected'),
        ),
      );
      final repository = OperationRecordRepositoryImpl(
        remoteDataSource: remoteDataSource,
        logger: _RecordingLogger(),
      );

      await expectLater(
        repository.reportOperation(
          doorId: '10001',
          action: OperationReportAction.autoCloseDelayChanged,
          operationSource: OperationReportSource.bluetooth,
          requestId: 'report-map-error',
        ),
        throwsA(
          isA<AppError>()
              .having((error) => error.code, 'code', AppErrorCode.serverError)
              .having((error) => error.businessCode, 'business code', 409)
              .having(
                (error) => error.requestId,
                'request ID',
                'report-map-error',
              )
              .having((error) => error.deviceId, 'door ID', '10001'),
        ),
      );
      expect(remoteDataSource.reportedDoorId, 10001);
      expect(
        remoteDataSource.reportedBody?.action,
        OperationReportAction.autoCloseDelayChanged,
      );
    },
  );
}

class _FakeOperationRecordApi implements OperationRecordApi {
  _FakeOperationRecordApi({this.reportResponse, this.reportError});

  final ApiEnvelopeDto<bool>? reportResponse;
  final Object? reportError;
  int? reportedDoorId;
  OperationReportRequestDto? reportedBody;
  Options? reportedOptions;

  @override
  Future<ApiEnvelopeDto<bool>> reportOperation(
    int doorId,
    OperationReportRequestDto body,
    Options options,
  ) async {
    reportedDoorId = doorId;
    reportedBody = body;
    reportedOptions = options;
    if (reportError != null) {
      throw reportError!;
    }
    return reportResponse!;
  }

  @override
  Future<ApiEnvelopeDto<OperationRecordPageResponseDto>> fetchOperationRecords(
    int doorId,
    int current,
    int size,
    Options options,
  ) => throw UnimplementedError();
}

class _FakeOperationRecordRemoteDataSource
    implements OperationRecordRemoteDataSource {
  _FakeOperationRecordRemoteDataSource({this.error});

  final Object? error;
  int? reportedDoorId;
  OperationReportRequestDto? reportedBody;

  @override
  Future<void> reportOperation({
    required int doorId,
    required OperationReportRequestDto body,
    required String requestId,
  }) async {
    reportedDoorId = doorId;
    reportedBody = body;
    if (error != null) {
      throw error!;
    }
  }

  @override
  Future<OperationRecordPageResponseDto> fetchOperationRecords({
    required int doorId,
    required int page,
    required int pageSize,
    required String requestId,
  }) => throw UnimplementedError();
}

class _CapturingHttpClientAdapter implements HttpClientAdapter {
  late RequestOptions requestOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestOptions = options;
    return ResponseBody.fromString(
      jsonEncode({'code': 200, 'success': true, 'data': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _RecordingLogger implements AppLogger {
  final List<String> errors = <String>[];

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
    errors.add(message);
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
