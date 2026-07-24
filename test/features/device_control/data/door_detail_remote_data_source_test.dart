import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/device_control/data/data_sources/door_detail_api.dart';
import 'package:flinx/features/device_control/data/data_sources/door_detail_remote_data_source.dart';
import 'package:flinx/features/device_control/data/dto/door_detail_response_dto.dart';
import 'package:flinx/features/device_control/data/dto/door_device_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the door-device response fields', () {
    final dto = DoorDeviceResponseDto.fromJson(const {
      'deviceId': '3',
      'sn': 'opener_B8F86211A9DC',
      'deviceType': 'opener',
      'deviceTypeLabel': 'Smart opener',
      'onlineStatus': 2,
      'bleName': 'opener_B8F86211A9DC',
      'bleConnectionStatus': 1,
      'wifiConnectionStatus': 2,
      'capabilities': ['DOOR_CONTROL'],
    });

    expect(dto.deviceId, '3');
    expect(dto.deviceType, 'opener');
    expect(dto.bleConnectionStatus, 1);
    expect(dto.wifiConnectionStatus, 2);
    expect(dto.capabilities, ['DOOR_CONTROL']);
  });

  test('parses the current door detail response fields', () {
    final dto = DoorDetailResponseDto.fromJson(const {
      'id': '12',
      'name': 'Main Gate',
      'doorType': 0,
      'onlineStatus': 2,
      'doorState': 0,
      'doorStateLabel': 'Unknown',
      'positionPercent': null,
      'operatedCycles': 0,
      'remainingCycles': 0,
      'ledStatus': 2,
      'ledStatusLabel': 'On',
      'autoCloseEnabled': false,
      'openReminderEnabled': true,
      'partialOpenValue': 60,
      'ignored': 'value',
    });

    expect(dto.id, '12');
    expect(dto.name, 'Main Gate');
    expect(dto.doorType, 0);
    expect(dto.onlineStatus, 2);
    expect(dto.doorState, 0);
    expect(dto.doorStateLabel, 'Unknown');
    expect(dto.positionPercent, isNull);
    expect(dto.operatedCycles, 0);
    expect(dto.remainingCycles, 0);
    expect(dto.ledStatus, 2);
    expect(dto.ledStatusLabel, 'On');
    expect(dto.autoCloseEnabled, isFalse);
    expect(dto.openReminderEnabled, isTrue);
    expect(dto.partialOpenValue, 60);
  });

  test('fetches door detail with door id and request id', () async {
    final api = _FakeDoorDetailApi(
      response: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: DoorDetailResponseDto(
          id: '12',
          name: 'Main Gate',
          operatedCycles: 123,
          remainingCycles: 4567,
        ),
      ),
    );
    final dataSource = DoorDetailRemoteDataSourceImpl(api: api);

    final detail = await dataSource.fetchDoorDetail(
      doorId: 12,
      requestId: 'door-detail-123',
    );

    expect(detail.name, 'Main Gate');
    expect(api.doorId, 12);
    expect(
      api.options.extra?[NetworkRequestExtras.requestId],
      'door-detail-123',
    );
  });

  test('accepts code 0 response', () async {
    final dataSource = DoorDetailRemoteDataSourceImpl(
      api: _FakeDoorDetailApi(
        response: const ApiEnvelopeDto(
          code: 0,
          success: true,
          data: DoorDetailResponseDto(id: '12', name: 'Main Gate'),
        ),
      ),
    );

    final detail = await dataSource.fetchDoorDetail(
      doorId: 12,
      requestId: 'door-detail-123',
    );

    expect(detail.id, '12');
  });

  test('fetches door devices with the same request correlation', () async {
    final api = _FakeDoorDetailApi(
      response: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: DoorDetailResponseDto(id: '12', name: 'Main Gate'),
      ),
      devicesResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: [
          DoorDeviceResponseDto(
            deviceId: '3',
            sn: 'opener_B8F86211A9DC',
            deviceType: 'opener',
            bleConnectionStatus: 1,
            wifiConnectionStatus: 1,
          ),
        ],
      ),
    );
    final dataSource = DoorDetailRemoteDataSourceImpl(api: api);

    final devices = await dataSource.fetchDoorDevices(
      doorId: 12,
      requestId: 'door-devices-123',
    );

    expect(devices.single.deviceType, 'opener');
    expect(api.devicesDoorId, 12);
    expect(
      api.devicesOptions.extra?[NetworkRequestExtras.requestId],
      'door-devices-123',
    );
  });

  test('rejects unsuccessful business response', () async {
    final dataSource = DoorDetailRemoteDataSourceImpl(
      api: _FakeDoorDetailApi(
        response: const ApiEnvelopeDto<DoorDetailResponseDto>(
          code: 500,
          success: false,
        ),
      ),
    );

    expect(
      () =>
          dataSource.fetchDoorDetail(doorId: 12, requestId: 'door-detail-123'),
      throwsA(
        isA<DoorDetailRemoteException>().having(
          (error) => error.kind,
          'kind',
          DoorDetailRemoteErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('rejects null data response', () async {
    final dataSource = DoorDetailRemoteDataSourceImpl(
      api: _FakeDoorDetailApi(
        response: const ApiEnvelopeDto<DoorDetailResponseDto>(
          code: 200,
          success: true,
        ),
      ),
    );

    expect(
      () =>
          dataSource.fetchDoorDetail(doorId: 12, requestId: 'door-detail-123'),
      throwsA(isA<DoorDetailRemoteException>()),
    );
  });

  test('converts DioException to remote network exception', () async {
    final dataSource = DoorDetailRemoteDataSourceImpl(
      api: _ThrowingDoorDetailApi(
        DioException(
          requestOptions: RequestOptions(path: 'app/doors/12'),
          type: DioExceptionType.connectionError,
          error: 'offline',
        ),
      ),
    );

    expect(
      () =>
          dataSource.fetchDoorDetail(doorId: 12, requestId: 'door-detail-123'),
      throwsA(
        isA<DoorDetailRemoteException>().having(
          (error) => error.kind,
          'kind',
          DoorDetailRemoteErrorKind.network,
        ),
      ),
    );
  });
}

class _FakeDoorDetailApi implements DoorDetailApi {
  _FakeDoorDetailApi({required this.response, this.devicesResponse});

  final ApiEnvelopeDto<DoorDetailResponseDto> response;
  final ApiEnvelopeDto<List<DoorDeviceResponseDto>>? devicesResponse;
  late int doorId;
  late Options options;
  late int devicesDoorId;
  late Options devicesOptions;

  @override
  Future<ApiEnvelopeDto<DoorDetailResponseDto>> fetchDoorDetail(
    int doorId,
    Options options,
  ) async {
    this.doorId = doorId;
    this.options = options;
    return response;
  }

  @override
  Future<ApiEnvelopeDto<List<DoorDeviceResponseDto>>> fetchDoorDevices(
    int doorId,
    Options options,
  ) async {
    devicesDoorId = doorId;
    devicesOptions = options;
    return devicesResponse!;
  }
}

class _ThrowingDoorDetailApi implements DoorDetailApi {
  const _ThrowingDoorDetailApi(this.error);

  final DioException error;

  @override
  Future<ApiEnvelopeDto<DoorDetailResponseDto>> fetchDoorDetail(
    int doorId,
    Options options,
  ) {
    throw error;
  }

  @override
  Future<ApiEnvelopeDto<List<DoorDeviceResponseDto>>> fetchDoorDevices(
    int doorId,
    Options options,
  ) {
    throw error;
  }
}
