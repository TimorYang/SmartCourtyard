import 'package:dio/dio.dart';
import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/network_exception.dart';
import 'package:flinx/features/device_control/data/data_sources/door_detail_remote_data_source.dart';
import 'package:flinx/features/device_control/data/dto/door_detail_response_dto.dart';
import 'package:flinx/features/device_control/data/dto/about_device_info_response_dto.dart';
import 'package:flinx/features/device_control/data/dto/door_device_response_dto.dart';
import 'package:flinx/features/device_control/data/repositories/door_detail_repository_impl.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps door detail dto to domain entity', () async {
    final repository = DoorDetailRepositoryImpl(
      remoteDataSource: const _FakeDoorDetailRemoteDataSource(
        DoorDetailResponseDto(
          id: '12',
          name: 'Main Gate',
          operatorAvatarFileId: 101,
          doorStateLabel: 'Closing',
          operatedCycles: 123,
          remainingCycles: 4567,
          ledStatus: 2,
          ledStatusLabel: 'On',
          autoCloseEnabled: true,
          openReminderEnabled: true,
          partialOpenValue: 60,
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
    expect(detail.operatorAvatarFileId, 101);
    expect(detail.doorState, DoorState.closing);
    expect(detail.doorStateLabel, 'Closing');
    expect(detail.operatedCycles, 123);
    expect(detail.remainingCycles, 4567);
    expect(detail.isLedEnabled, isTrue);
    expect(detail.autoCloseEnabled, isTrue);
    expect(detail.openReminderEnabled, isTrue);
    expect(detail.partialOpenValue, 60);
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

  test('maps about-device dto to domain entity', () async {
    final repository = DoorDetailRepositoryImpl(
      remoteDataSource: const _FakeDoorDetailRemoteDataSource(
        DoorDetailResponseDto(id: '12', name: 'Main Gate'),
        aboutDeviceInfo: AboutDeviceInfoResponseDto(
          deviceId: '3',
          sn: 'opener_B8F86211A9DC',
          deviceType: 'opener',
          deviceTypeLabel: 'opener',
          bluetoothName: 'opener_B8F86211A9DC',
          hardwareVersion: '1.0.0',
          firmwareVersion: '2.0.0',
          updateAvailable: true,
          availableVersion: '2.1.0',
        ),
      ),
      logger: const _NoopLogger(),
    );

    final info = await repository.fetchAboutDeviceInfo(
      doorId: '12',
      deviceId: '3',
      requestId: 'about-device-123',
    );

    expect(info.deviceId, '3');
    expect(info.bluetoothName, 'opener_B8F86211A9DC');
    expect(info.firmwareVersion, '2.0.0');
    expect(info.hardwareVersion, '1.0.0');
  });

  test('rejects invalid door id before requesting remote data', () async {
    final repository = DoorDetailRepositoryImpl(
      remoteDataSource: const _FakeDoorDetailRemoteDataSource(
        DoorDetailResponseDto(id: '12', name: 'Main Gate'),
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

  test('unbinds a device with parsed IDs', () async {
    final dataSource = _RecordingDoorDetailRemoteDataSource();
    final repository = DoorDetailRepositoryImpl(
      remoteDataSource: dataSource,
      logger: const _NoopLogger(),
    );

    await repository.unbindDoorDevice(
      doorId: '12',
      deviceId: '3',
      requestId: 'unbind-door-device-123',
    );

    expect(dataSource.doorId, 12);
    expect(dataSource.deviceId, 3);
    expect(dataSource.requestId, 'unbind-door-device-123');
  });
}

class _RecordingDoorDetailRemoteDataSource
    extends _FakeDoorDetailRemoteDataSource {
  _RecordingDoorDetailRemoteDataSource()
    : super(const DoorDetailResponseDto(id: '12', name: 'Main Gate'));

  int? doorId;
  int? deviceId;
  String? requestId;

  @override
  Future<void> unbindDoorDevice({
    required int doorId,
    required int deviceId,
    required String requestId,
  }) async {
    this.doorId = doorId;
    this.deviceId = deviceId;
    this.requestId = requestId;
  }
}

class _FakeDoorDetailRemoteDataSource implements DoorDetailRemoteDataSource {
  const _FakeDoorDetailRemoteDataSource(this.detail, {this.aboutDeviceInfo});

  final DoorDetailResponseDto detail;
  final AboutDeviceInfoResponseDto? aboutDeviceInfo;

  @override
  Future<DoorDetailResponseDto> fetchDoorDetail({
    required int doorId,
    required String requestId,
  }) async {
    return detail;
  }

  @override
  Future<List<DoorDeviceResponseDto>> fetchDoorDevices({
    required int doorId,
    required String requestId,
  }) async => const [];

  @override
  Future<AboutDeviceInfoResponseDto> fetchAboutDeviceInfo({
    required int doorId,
    required int deviceId,
    required String requestId,
  }) async => aboutDeviceInfo!;

  @override
  Future<void> unbindDoorDevice({
    required int doorId,
    required int deviceId,
    required String requestId,
  }) async {}
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

  @override
  Future<List<DoorDeviceResponseDto>> fetchDoorDevices({
    required int doorId,
    required String requestId,
  }) {
    throw error;
  }

  @override
  Future<AboutDeviceInfoResponseDto> fetchAboutDeviceInfo({
    required int doorId,
    required int deviceId,
    required String requestId,
  }) => throw error;

  @override
  Future<void> unbindDoorDevice({
    required int doorId,
    required int deviceId,
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
