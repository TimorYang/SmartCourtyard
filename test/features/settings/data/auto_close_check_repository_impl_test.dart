import 'package:dio/dio.dart';
import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/network_exception.dart';
import 'package:flinx/features/settings/data/data_sources/auto_close_check_remote_data_source.dart';
import 'package:flinx/features/settings/data/dto/auto_close_check_response_dto.dart';
import 'package:flinx/features/settings/data/repositories/auto_close_check_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parses numeric business ids before calling the remote source',
    () async {
      final remote = _FakeRemoteDataSource(
        const AutoCloseCheckResponseDto(autoCloseAllowed: true),
      );
      final repository = AutoCloseCheckRepositoryImpl(
        remoteDataSource: remote,
        logger: const _NoopLogger(),
      );

      final result = await repository.checkAutoClose(
        doorId: ' 10001 ',
        deviceId: '20001',
        requestId: 'auto-close-repository-1',
      );

      expect(result.autoCloseAllowed, isTrue);
      expect(remote.doorId, 10001);
      expect(remote.deviceId, 20001);
      expect(remote.requestId, 'auto-close-repository-1');
    },
  );

  test('rejects invalid ids without issuing a request', () async {
    final remote = _FakeRemoteDataSource(
      const AutoCloseCheckResponseDto(autoCloseAllowed: true),
    );
    final repository = AutoCloseCheckRepositoryImpl(
      remoteDataSource: remote,
      logger: const _NoopLogger(),
    );

    await expectLater(
      repository.checkAutoClose(
        doorId: 'door-a',
        deviceId: '20001',
        requestId: 'auto-close-repository-invalid',
      ),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.unknown)
            .having(
              (error) => error.messageKey,
              'messageKey',
              'auto_close_check_invalid_id',
            ),
      ),
    );
    expect(remote.calls, 0);
  });

  test('maps an invalid remote response to a server error', () async {
    final repository = AutoCloseCheckRepositoryImpl(
      remoteDataSource: _ThrowingRemoteDataSource(
        const AutoCloseCheckRemoteException.invalidResponse(),
      ),
      logger: const _NoopLogger(),
    );

    await expectLater(
      repository.checkAutoClose(
        doorId: '10001',
        deviceId: '20001',
        requestId: 'auto-close-repository-invalid-response',
      ),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.serverError)
            .having(
              (error) => error.messageKey,
              'messageKey',
              'auto_close_check_invalid_response',
            ),
      ),
    );
  });

  test('maps a network remote error to a retryable app error', () async {
    final network = NetworkException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: 'auto-close/check'),
        type: DioExceptionType.connectionError,
      ),
    );
    final repository = AutoCloseCheckRepositoryImpl(
      remoteDataSource: _ThrowingRemoteDataSource(
        AutoCloseCheckRemoteException.fromNetwork(network),
      ),
      logger: const _NoopLogger(),
    );

    await expectLater(
      repository.checkAutoClose(
        doorId: '10001',
        deviceId: '20001',
        requestId: 'auto-close-repository-network',
      ),
      throwsA(
        isA<AppError>()
            .having(
              (error) => error.code,
              'code',
              AppErrorCode.networkUnavailable,
            )
            .having((error) => error.retryable, 'retryable', isTrue),
      ),
    );
  });
}

class _FakeRemoteDataSource implements AutoCloseCheckRemoteDataSource {
  _FakeRemoteDataSource(this.response);

  final AutoCloseCheckResponseDto response;
  var calls = 0;
  int? doorId;
  int? deviceId;
  String? requestId;

  @override
  Future<AutoCloseCheckResponseDto> checkAutoClose({
    required int doorId,
    required int deviceId,
    required String requestId,
  }) async {
    calls++;
    this.doorId = doorId;
    this.deviceId = deviceId;
    this.requestId = requestId;
    return response;
  }
}

class _ThrowingRemoteDataSource implements AutoCloseCheckRemoteDataSource {
  const _ThrowingRemoteDataSource(this.error);

  final AutoCloseCheckRemoteException error;

  @override
  Future<AutoCloseCheckResponseDto> checkAutoClose({
    required int doorId,
    required int deviceId,
    required String requestId,
  }) => Future<AutoCloseCheckResponseDto>.error(error);
}

class _NoopLogger implements AppLogger {
  const _NoopLogger();

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

  @override
  void error(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
