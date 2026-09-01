import 'package:dio/dio.dart';
import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/api_business_failure.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/device_control/data/data_sources/remote_door_command_api.dart';
import 'package:flinx/features/device_control/data/data_sources/remote_door_command_remote_data_source.dart';
import 'package:flinx/features/device_control/data/dto/remote_door_command_request_dto.dart';
import 'package:flinx/features/device_control/data/dto/remote_door_command_response_dto.dart';
import 'package:flinx/features/device_control/data/repositories/remote_door_command_repository_impl.dart';
import 'package:flinx/features/device_control/domain/entities/remote_door_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes the five supported remote actions', () {
    expect(
      RemoteDoorCommandAction.values
          .map(
            (action) =>
                RemoteDoorCommandRequestDto(action: action).toJson()['action'],
          )
          .toList(),
      ['OPEN', 'CLOSE', 'STOP', 'LED_ON', 'LED_OFF'],
    );
  });

  test('parses the complete remote command response', () {
    final dto = RemoteDoorCommandResponseDto.fromJson(const {
      'commandId': 'command-1',
      'doorId': 12,
      'commandType': 'DOOR_CONTROL',
      'action': 'OPEN',
      'status': 'FAILED',
      'stateConfirmationStatus': 'TIMEOUT',
      'deviceResultCode': 3,
      'failureCategory': 'DEVICE_ACK_TIMEOUT',
      'failureReason': 'timeout',
      'createdAt': 100,
      'publishedAt': 200,
      'deviceAckAt': null,
      'stateReportedAt': null,
    });

    expect(dto.commandId, 'command-1');
    expect(dto.doorId, '12');
    expect(dto.commandType, 'DOOR_CONTROL');
    expect(dto.deviceResultCode, 3);
    expect(dto.failureCategory, 'DEVICE_ACK_TIMEOUT');
    expect(dto.createdAt, 100);
    expect(dto.publishedAt, 200);
    expect(dto.deviceAckAt, isNull);
  });

  test('passes the request id when submitting a command', () async {
    final api = _FakeRemoteDoorCommandApi();
    final dataSource = RemoteDoorCommandRemoteDataSourceImpl(api: api);

    await dataSource.submitCommand(
      doorId: 12,
      body: const RemoteDoorCommandRequestDto(
        action: RemoteDoorCommandAction.open,
      ),
      requestId: 'remote-command-1',
    );
    expect(api.paths, ['submit:12:OPEN']);
    expect(
      api.options
          .map((options) => options.extra?[NetworkRequestExtras.requestId])
          .toSet(),
      {'remote-command-1'},
    );
  });

  test('preserves a business failure message', () async {
    final dataSource = RemoteDoorCommandRemoteDataSourceImpl(
      api: _FakeRemoteDoorCommandApi(
        response: const ApiEnvelopeDto(
          code: 409,
          success: false,
          msg: 'The door is busy',
        ),
      ),
    );

    await expectLater(
      dataSource.submitCommand(
        doorId: 12,
        body: const RemoteDoorCommandRequestDto(
          action: RemoteDoorCommandAction.open,
        ),
        requestId: 'remote-command-1',
      ),
      throwsA(
        isA<RemoteDoorCommandRemoteException>()
            .having(
              (error) => error.kind,
              'kind',
              RemoteDoorCommandRemoteErrorKind.businessFailure,
            )
            .having(
              (error) => error.businessFailure?.message,
              'message',
              'The door is busy',
            ),
      ),
    );
  });

  test('preserves business failure metadata in the repository error', () async {
    final repository = RemoteDoorCommandRepositoryImpl(
      remoteDataSource: _ThrowingRemoteDoorCommandRemoteDataSource(
        RemoteDoorCommandRemoteException.businessFailure(
          ApiBusinessFailure(
            code: 409,
            messageKey: 'app.door.busy',
            message: 'The door is busy',
          ),
        ),
      ),
      logger: const _NoopLogger(),
    );

    await expectLater(
      repository.submitCommand(
        doorId: '12',
        action: RemoteDoorCommandAction.open,
        requestId: 'remote-command-business-failure',
      ),
      throwsA(
        isA<AppError>()
            .having((error) => error.businessCode, 'businessCode', 409)
            .having(
              (error) => error.businessMessageKey,
              'businessMessageKey',
              'app.door.busy',
            )
            .having(
              (error) => error.userMessage,
              'userMessage',
              'The door is busy',
            )
            .having(
              (error) => error.requestId,
              'requestId',
              'remote-command-business-failure',
            )
            .having((error) => error.deviceId, 'deviceId', '12'),
      ),
    );
  });

  test('maps wire status and failures into domain values', () async {
    final repository = RemoteDoorCommandRepositoryImpl(
      remoteDataSource: _FakeRemoteDoorCommandRemoteDataSource(
        const RemoteDoorCommandResponseDto(
          commandId: 'command-1',
          doorId: '12',
          action: 'LED_ON',
          status: 'UNCONFIRMED',
          failureCategory: 'DEVICE_ACK_TIMEOUT',
        ),
      ),
      logger: const _NoopLogger(),
    );

    final command = await repository.submitCommand(
      doorId: '12',
      action: RemoteDoorCommandAction.ledOn,
      requestId: 'remote-command-1',
    );

    expect(command.action, RemoteDoorCommandAction.ledOn);
    expect(command.status, RemoteDoorCommandStatus.unconfirmed);
    expect(command.status.isTerminal, isTrue);
    expect(command.failureCategory, 'DEVICE_ACK_TIMEOUT');
  });

  test('rejects a response for a different door', () async {
    final repository = RemoteDoorCommandRepositoryImpl(
      remoteDataSource: _FakeRemoteDoorCommandRemoteDataSource(
        const RemoteDoorCommandResponseDto(
          commandId: 'command-1',
          doorId: '99',
          action: 'OPEN',
          status: 'SUCCEEDED',
        ),
      ),
      logger: const _NoopLogger(),
    );

    await expectLater(
      repository.submitCommand(
        doorId: '12',
        action: RemoteDoorCommandAction.open,
        requestId: 'remote-command-1',
      ),
      throwsA(
        isA<AppError>().having(
          (error) => error.code,
          'code',
          AppErrorCode.serverError,
        ),
      ),
    );
  });
}

class _FakeRemoteDoorCommandApi implements RemoteDoorCommandApi {
  _FakeRemoteDoorCommandApi({
    this.response = const ApiEnvelopeDto(
      code: 200,
      success: true,
      data: RemoteDoorCommandResponseDto(
        commandId: 'command-1',
        doorId: '12',
        action: 'OPEN',
        status: 'PROCESSING',
      ),
    ),
  });

  final List<String> paths = <String>[];
  final List<Options> options = <Options>[];
  final ApiEnvelopeDto<RemoteDoorCommandResponseDto> response;

  @override
  Future<ApiEnvelopeDto<RemoteDoorCommandResponseDto>> submitCommand(
    int doorId,
    RemoteDoorCommandRequestDto body,
    Options options,
  ) async {
    paths.add('submit:$doorId:${body.action.wireValue}');
    this.options.add(options);
    return response;
  }
}

class _FakeRemoteDoorCommandRemoteDataSource
    implements RemoteDoorCommandRemoteDataSource {
  const _FakeRemoteDoorCommandRemoteDataSource(this.response);

  final RemoteDoorCommandResponseDto response;

  @override
  Future<RemoteDoorCommandResponseDto> submitCommand({
    required int doorId,
    required RemoteDoorCommandRequestDto body,
    required String requestId,
  }) async => response;
}

class _ThrowingRemoteDoorCommandRemoteDataSource
    implements RemoteDoorCommandRemoteDataSource {
  const _ThrowingRemoteDoorCommandRemoteDataSource(this.exception);

  final RemoteDoorCommandRemoteException exception;

  @override
  Future<RemoteDoorCommandResponseDto> submitCommand({
    required int doorId,
    required RemoteDoorCommandRequestDto body,
    required String requestId,
  }) async => throw exception;
}

class _NoopLogger implements AppLogger {
  const _NoopLogger();

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
  }) {}
}
