import 'package:dio/dio.dart';
import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/network_exception.dart';
import 'package:flinx/features/device_control/data/data_sources/door_detail_remote_data_source.dart';
import 'package:flinx/features/device_control/data/dto/door_detail_response_dto.dart';
import 'package:flinx/features/device_control/data/repositories/door_detail_repository_impl.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps door detail dto to domain entity', () async {
    final repository = DoorDetailRepositoryImpl(
      remoteDataSource: const _FakeDoorDetailRemoteDataSource(
        DoorDetailResponseDto(
          id: 12,
          name: 'Main Gate',
          sceneId: 7,
          doorStateLabel: 'Closing',
          operatedCycles: 123,
          remainingCycles: 4567,
          hardwareSn: 'SN-001',
        ),
      ),
      logger: const _NoopLogger(),
    );

    final detail = await repository.fetchDoorDetail(
      doorId: '12',
      requestId: 'door-detail-123',
    );

    expect(detail.id, '12');
    expect(detail.name, 'Main Gate');
    expect(detail.sceneId, 7);
    expect(detail.doorState, DoorState.closing);
    expect(detail.doorStateLabel, 'Closing');
    expect(detail.operatedCycles, 123);
    expect(detail.remainingCycles, 4567);
    expect(detail.hardwareDeviceId, 'SN-001');
  });

  test('maps network failure to retryable app error', () async {
    final repository = DoorDetailRepositoryImpl(
      remoteDataSource: _FailingDoorDetailRemoteDataSource(
        DoorDetailRemoteException.fromNetwork(
          NetworkException.fromDio(
            DioException(
              requestOptions: RequestOptions(path: 'app/doors/12'),
              type: DioExceptionType.connectionError,
              error: 'offline',
            ),
          ),
        ),
      ),
      logger: const _NoopLogger(),
    );

    await expectLater(
      repository.fetchDoorDetail(doorId: '12', requestId: 'door-detail-123'),
      throwsA(
        isA<AppError>()
            .having(
              (error) => error.code,
              'code',
              AppErrorCode.networkUnavailable,
            )
            .having((error) => error.retryable, 'retryable', isTrue)
            .having((error) => error.requestId, 'requestId', 'door-detail-123'),
      ),
    );
  });

  test('rejects invalid door id before requesting remote data', () async {
    final repository = DoorDetailRepositoryImpl(
      remoteDataSource: const _FakeDoorDetailRemoteDataSource(
        DoorDetailResponseDto(id: 12, name: 'Main Gate'),
      ),
      logger: const _NoopLogger(),
    );

    await expectLater(
      repository.fetchDoorDetail(
        doorId: 'not-a-number',
        requestId: 'door-detail-123',
      ),
      throwsA(
        isA<AppError>().having(
          (error) => error.messageKey,
          'messageKey',
          'door_detail_invalid_door_id',
        ),
      ),
    );
  });
}

class _FakeDoorDetailRemoteDataSource implements DoorDetailRemoteDataSource {
  const _FakeDoorDetailRemoteDataSource(this.detail);

  final DoorDetailResponseDto detail;

  @override
  Future<DoorDetailResponseDto> fetchDoorDetail({
    required int doorId,
    required String requestId,
  }) async {
    return detail;
  }
}

class _FailingDoorDetailRemoteDataSource implements DoorDetailRemoteDataSource {
  const _FailingDoorDetailRemoteDataSource(this.error);

  final DoorDetailRemoteException error;

  @override
  Future<DoorDetailResponseDto> fetchDoorDetail({
    required int doorId,
    required String requestId,
  }) {
    throw error;
  }
}

class _NoopLogger implements AppLogger {
  const _NoopLogger();

  @override
  void error(
    String message, {
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void info(
    String message, {
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void warning(
    String message, {
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}
}
