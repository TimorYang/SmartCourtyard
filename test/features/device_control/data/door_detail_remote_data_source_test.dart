import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/device_control/data/data_sources/door_detail_api.dart';
import 'package:flinx/features/device_control/data/data_sources/door_detail_remote_data_source.dart';
import 'package:flinx/features/device_control/data/dto/door_detail_response_dto.dart';
import 'package:flinx/features/device_control/data/dto/about_device_info_response_dto.dart';
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

  test('parses and serializes about-device response fields', () {
    final dto = AboutDeviceInfoResponseDto.fromJson(const {
      'deviceId': 10001,
      'sn': 'opener_B8F86211A9DC',
      'deviceType': 'opener',
      'deviceTypeLabel': 'opener',
      'bluetoothName': 'opener_B8F86211A9DC',
      'hardwareVersion': '1.0.0',
      'firmwareVersion': '2.0.0',
      'updateAvailable': true,
      'availableVersion': '2.1.0',
    });

    expect(dto.deviceId, '10001');
    expect(dto.firmwareVersion, '2.0.0');
    expect(dto.updateAvailable, isTrue);
    expect(dto.toJson()['hardwareVersion'], '1.0.0');
  });

  test('parses the current door detail response fields', () {
    final dto = DoorDetailResponseDto.fromJson(const {
      'id': '12',
      'name': 'Main Gate',
      'doorType': 0,
      'onlineStatus': 2,
      'relationType': 1,
      'effectiveCapabilities': ['DOOR_CONTROL', ' LED_CONTROL '],
      'doorState': 0,
      'doorStateLabel': 'Unknown',
      'positionPercent': null,
      'operatorAvatarFileId': '101',
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
    expect(dto.relationType, 1);
    expect(dto.effectiveCapabilities, ['DOOR_CONTROL', ' LED_CONTROL ']);
    expect(dto.doorState, 0);
    expect(dto.doorStateLabel, 'Unknown');
    expect(dto.positionPercent, isNull);
    expect(dto.operatorAvatarFileId, 101);
    expect(dto.operatedCycles, 0);
    expect(dto.remainingCycles, 0);
    expect(dto.ledStatus, 2);
    expect(dto.ledStatusLabel, 'On');
    expect(dto.autoCloseEnabled, isFalse);
    expect(dto.openReminderEnabled, isTrue);
    expect(dto.partialOpenValue, 60);
  });

  test('defaults missing or empty effective capabilities to an empty list', () {
    final missing = DoorDetailResponseDto.fromJson(const {
      'id': '12',
      'name': 'Main Gate',
    });
    final empty = DoorDetailResponseDto.fromJson(const {
      'id': '12',
      'name': 'Main Gate',
      'effectiveCapabilities': [],
    });

    expect(missing.effectiveCapabilities, isEmpty);
    expect(empty.effectiveCapabilities, isEmpty);
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

  test(
    'fetches about device information with both path IDs and request ID',
    () async {
      final api = _FakeDoorDetailApi(
        response: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: DoorDetailResponseDto(id: '12', name: 'Main Gate'),
        ),
        aboutDeviceInfoResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: AboutDeviceInfoResponseDto(
            deviceId: '3',
            sn: 'opener_B8F86211A9DC',
            deviceType: 'opener',
            deviceTypeLabel: 'Smart opener',
            bluetoothName: 'opener_B8F86211A9DC',
            hardwareVersion: '1.0.0',
            firmwareVersion: '2.0.0',
            updateAvailable: true,
            availableVersion: '2.1.0',
          ),
        ),
      );
      final dataSource = DoorDetailRemoteDataSourceImpl(api: api);

      final info = await dataSource.fetchAboutDeviceInfo(
        doorId: 12,
        deviceId: 3,
        requestId: 'about-device-123',
      );

      expect(info.bluetoothName, 'opener_B8F86211A9DC');
      expect(api.aboutDeviceDoorId, 12);
      expect(api.aboutDeviceId, 3);
      expect(
        api.aboutDeviceOptions.extra?[NetworkRequestExtras.requestId],
        'about-device-123',
      );
    },
  );

  test('rejects unsuccessful business response', () async {
    final dataSource = DoorDetailRemoteDataSourceImpl(
      api: _FakeDoorDetailApi(
        response: const ApiEnvelopeDto<DoorDetailResponseDto>(
          code: 500,
          success: false,
          msg: 'Unable to load door details',
        ),
      ),
    );

    expect(
      () =>
          dataSource.fetchDoorDetail(doorId: 12, requestId: 'door-detail-123'),
      throwsA(
        isA<DoorDetailRemoteException>()
            .having(
              (error) => error.kind,
              'kind',
              DoorDetailRemoteErrorKind.businessFailure,
            )
            .having(
              (error) => error.businessFailure?.message,
              'message',
              'Unable to load door details',
            ),
      ),
    );
  });

  test('unbinds a door device with request correlation', () async {
    final api = _FakeDoorDetailApi(
      response: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: DoorDetailResponseDto(id: '12', name: 'Main Gate'),
      ),
      unbindResponse: const ApiEnvelopeDto(code: 0, success: true, data: true),
    );
    final dataSource = DoorDetailRemoteDataSourceImpl(api: api);

    await dataSource.unbindDoorDevice(
      doorId: 12,
      deviceId: 3,
      requestId: 'unbind-door-device-123',
    );

    expect(api.unbindDoorId, 12);
    expect(api.unbindDeviceId, 3);
    expect(
      api.unbindOptions.extra?[NetworkRequestExtras.requestId],
      'unbind-door-device-123',
    );
  });

  test('rejects a false unbind response', () async {
    final dataSource = DoorDetailRemoteDataSourceImpl(
      api: _FakeDoorDetailApi(
        response: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: DoorDetailResponseDto(id: '12', name: 'Main Gate'),
        ),
        unbindResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: false,
        ),
      ),
    );

    await expectLater(
      dataSource.unbindDoorDevice(
        doorId: 12,
        deviceId: 3,
        requestId: 'unbind-door-device-123',
      ),
      throwsA(isA<DoorDetailRemoteException>()),
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
  _FakeDoorDetailApi({
    required this.response,
    this.devicesResponse,
    this.aboutDeviceInfoResponse,
    this.unbindResponse,
  });

  final ApiEnvelopeDto<DoorDetailResponseDto> response;
  final ApiEnvelopeDto<List<DoorDeviceResponseDto>>? devicesResponse;
  final ApiEnvelopeDto<AboutDeviceInfoResponseDto>? aboutDeviceInfoResponse;
  final ApiEnvelopeDto<bool>? unbindResponse;
  late int doorId;
  late Options options;
  late int devicesDoorId;
  late Options devicesOptions;
  late int unbindDoorId;
  late int unbindDeviceId;
  late Options unbindOptions;
  late int aboutDeviceDoorId;
  late int aboutDeviceId;
  late Options aboutDeviceOptions;

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

  @override
  Future<ApiEnvelopeDto<AboutDeviceInfoResponseDto>> fetchAboutDeviceInfo(
    int doorId,
    int deviceId,
    Options options,
  ) async {
    aboutDeviceDoorId = doorId;
    aboutDeviceId = deviceId;
    aboutDeviceOptions = options;
    return aboutDeviceInfoResponse!;
  }

  @override
  Future<ApiEnvelopeDto<bool>> unbindDoorDevice(
    int doorId,
    int deviceId,
    Options options,
  ) async {
    unbindDoorId = doorId;
    unbindDeviceId = deviceId;
    unbindOptions = options;
    return unbindResponse!;
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

  @override
  Future<ApiEnvelopeDto<AboutDeviceInfoResponseDto>> fetchAboutDeviceInfo(
    int doorId,
    int deviceId,
    Options options,
  ) => throw error;

  @override
  Future<ApiEnvelopeDto<bool>> unbindDoorDevice(
    int doorId,
    int deviceId,
    Options options,
  ) {
    throw error;
  }
}
