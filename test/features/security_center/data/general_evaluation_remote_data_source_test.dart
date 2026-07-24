import 'package:dio/dio.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/features/security_center/data/data_sources/general_evaluation_api.dart';
import 'package:flinx/features/security_center/data/data_sources/general_evaluation_remote_data_source.dart';
import 'package:flinx/features/security_center/data/dto/general_evaluation_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('logs endpoint and range when an envelope is invalid', () async {
    final logger = _CapturingLogger();
    final source = GeneralEvaluationRemoteDataSourceImpl(
      api: _FakeGeneralEvaluationApi(),
      logger: logger,
    );

    await expectLater(
      source.operations(doorId: 10, range: 1, requestId: 'request-1'),
      throwsA(isA<GeneralEvaluationRemoteException>()),
    );

    expect(logger.warningContexts.single, {
      'endpoint': 'operations',
      'range': 1,
      'code': 200,
      'success': false,
      'hasData': false,
      'dataType': null,
    });
  });
}

class _FakeGeneralEvaluationApi implements GeneralEvaluationApi {
  @override
  Future<ApiEnvelopeDto<BalanceResponseDto>> balance(
    int doorId,
    String requestId,
    Options options,
  ) async => const ApiEnvelopeDto(
    code: 200,
    success: true,
    data: BalanceResponseDto(),
  );

  @override
  Future<ApiEnvelopeDto<GeneralEvaluationResponseDto>> general(
    int doorId,
    Options options,
  ) async => const ApiEnvelopeDto(
    code: 200,
    success: true,
    data: GeneralEvaluationResponseDto(),
  );

  @override
  Future<ApiEnvelopeDto<OperationStatisticsDto>> operations(
    int doorId,
    int range,
    Options options,
  ) async => const ApiEnvelopeDto(code: 200, success: false);
}

class _CapturingLogger implements AppLogger {
  final List<Map<String, Object?>> warningContexts = [];

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
  }) {
    warningContexts.add(context);
  }
}
