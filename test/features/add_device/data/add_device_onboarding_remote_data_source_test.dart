import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/add_device/data/data_sources/add_device_onboarding_api.dart';
import 'package:flinx/features/add_device/data/data_sources/add_device_onboarding_remote_data_source.dart';
import 'package:flinx/features/add_device/data/dto/add_force_door_request_dto.dart';
import 'package:flinx/features/add_device/data/dto/binding_status_response_dto.dart';
import 'package:flinx/features/add_device/data/dto/force_door_response_dto.dart';
import 'package:flinx/features/add_device/data/dto/onboarding_device_key_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validateBindingStatus accepts an available serial number', () async {
    final dataSource = AddDeviceOnboardingRemoteDataSourceImpl(
      api: _FakeAddDeviceOnboardingApi(
        bindingStatusResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: BindingStatusResponseDto(
            sn: 'SN-001',
            bound: false,
            ownedByCurrentUser: false,
            canBind: true,
          ),
        ),
      ),
    );

    await dataSource.validateBindingStatus(
      sn: 'SN-001',
      requestId: 'request-0',
    );
  });

  test('validateBindingStatus preserves the server error message', () async {
    final dataSource = AddDeviceOnboardingRemoteDataSourceImpl(
      api: _FakeAddDeviceOnboardingApi(
        bindingStatusResponse: const ApiEnvelopeDto(
          code: 100409,
          success: false,
          msg: 'This device has already been bound.',
        ),
      ),
    );

    expect(
      () => dataSource.validateBindingStatus(
        sn: 'SN-001',
        requestId: 'request-0',
      ),
      throwsA(
        isA<AddDeviceOnboardingRemoteException>().having(
          (error) => error.serverMessage,
          'serverMessage',
          'This device has already been bound.',
        ),
      ),
    );
  });

  test('validateBindingStatus rejects an unavailable serial number', () async {
    final dataSource = AddDeviceOnboardingRemoteDataSourceImpl(
      api: _FakeAddDeviceOnboardingApi(
        bindingStatusResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: BindingStatusResponseDto(
            sn: 'SN-001',
            bound: true,
            ownedByCurrentUser: false,
            canBind: false,
          ),
        ),
      ),
    );

    expect(
      () => dataSource.validateBindingStatus(
        sn: 'SN-001',
        requestId: 'request-0',
      ),
      throwsA(isA<AddDeviceOnboardingRemoteException>()),
    );
  });

  test('fetchDeviceKey accepts code 0 and returns device key data', () async {
    final dataSource = AddDeviceOnboardingRemoteDataSourceImpl(
      api: _FakeAddDeviceOnboardingApi(
        deviceKeyResponse: const ApiEnvelopeDto(
          code: 0,
          success: true,
          data: OnboardingDeviceKeyResponseDto(
            sn: 'SN-001',
            aesKey: '0123456789abcdef0123456789abcdef',
            aesKeyVersion: 'v1',
          ),
        ),
      ),
    );

    final result = await dataSource.fetchDeviceKey(
      sn: 'SN-001',
      requestId: 'request-1',
    );

    expect(result.sn, 'SN-001');
    expect(result.aesKey, '0123456789abcdef0123456789abcdef');
  });

  test('fetchDeviceKey rejects missing aesKey', () async {
    final dataSource = AddDeviceOnboardingRemoteDataSourceImpl(
      api: _FakeAddDeviceOnboardingApi(
        deviceKeyResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: OnboardingDeviceKeyResponseDto(
            sn: 'SN-001',
            aesKey: '',
            aesKeyVersion: 'v1',
          ),
        ),
      ),
    );

    expect(
      () => dataSource.fetchDeviceKey(sn: 'SN-001', requestId: 'request-1'),
      throwsA(isA<AddDeviceOnboardingRemoteException>()),
    );
  });

  test('addForceDoor accepts code 200 and returns door data', () async {
    final api = _FakeAddDeviceOnboardingApi(
      addDoorResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: ForceDoorResponseDto(id: 7, name: 'Garage door'),
      ),
    );
    final dataSource = AddDeviceOnboardingRemoteDataSourceImpl(api: api);

    final result = await dataSource.addForceDoor(
      sn: 'SN-001',
      doorId: '7',
      doorType: 2,
      requestId: 'request-2',
    );

    expect(result.id, 7);
    expect(result.name, 'Garage door');
    expect(api.lastAddForceDoorRequest?.toJson(), {
      'sn': 'SN-001',
      'doorId': '7',
    });
    expect(
      api.lastAddForceDoorOptions?.extra?[NetworkRequestExtras.requestId],
      'request-2',
    );
  });

  test('addForceDoor sends doorType when creating a new door', () async {
    final api = _FakeAddDeviceOnboardingApi();
    final dataSource = AddDeviceOnboardingRemoteDataSourceImpl(api: api);

    await dataSource.addForceDoor(
      sn: 'SN-001',
      doorType: 4,
      requestId: 'request-2',
    );

    expect(api.lastAddForceDoorRequest?.toJson(), {
      'sn': 'SN-001',
      'doorType': 4,
    });
  });

  test(
    'addForceDoor accepts code 200 regardless of envelope success flag',
    () async {
      final dataSource = AddDeviceOnboardingRemoteDataSourceImpl(
        api: _FakeAddDeviceOnboardingApi(
          addDoorResponse: const ApiEnvelopeDto(
            code: 200,
            success: false,
            data: ForceDoorResponseDto(id: 7),
          ),
        ),
      );

      final result = await dataSource.addForceDoor(
        sn: 'SN-001',
        doorId: '7',
        doorType: 0,
        requestId: 'request-2',
      );

      expect(result.id, 7);
    },
  );

  test('parses the latest force door response data structure', () {
    final result = ForceDoorResponseDto.fromJson({
      'id': '16',
      'name': 'inner dongle-Noru_B8F8620EACA0',
      'doorType': 0,
      'controlMode': 2,
      'onlineStatus': 1,
      'doorState': 0,
      'operatedCycles': 14,
      'remainingCycles': 65535,
      'associatedDevices': [
        {
          'deviceType': 'dongle',
          'associated': true,
          'primaryControl': true,
          'onlineStatus': 1,
          'bleName': 'Noru_B8F8620EACA0',
          'wifiConnectionStatus': 'CONNECTED',
          'capabilities': ['DOOR_CONTROL', 'LED_CONTROL'],
        },
      ],
    });

    expect(result.id, 16);
    expect(result.associatedDevices, hasLength(1));
    expect(result.associatedDevices.single.bleName, 'Noru_B8F8620EACA0');
    expect(result.associatedDevices.single.capabilities, [
      'DOOR_CONTROL',
      'LED_CONTROL',
    ]);
  });

  test('addForceDoor rejects failed envelope', () async {
    final dataSource = AddDeviceOnboardingRemoteDataSourceImpl(
      api: _FakeAddDeviceOnboardingApi(
        addDoorResponse: const ApiEnvelopeDto(
          code: 500,
          success: false,
          data: ForceDoorResponseDto(id: 7),
        ),
      ),
    );

    expect(
      () => dataSource.addForceDoor(
        sn: 'SN-001',
        doorId: '7',
        doorType: 0,
        requestId: 'request-2',
      ),
      throwsA(isA<AddDeviceOnboardingRemoteException>()),
    );
  });

  test('addForceDoor preserves server message key from failed envelope', () {
    final dataSource = AddDeviceOnboardingRemoteDataSourceImpl(
      api: _FakeAddDeviceOnboardingApi(
        addDoorResponse: const ApiEnvelopeDto(
          code: 100408,
          success: false,
          msg: '设备不存在',
          messageKey: 'app.door.device_not_exists',
        ),
      ),
    );

    expect(
      () => dataSource.addForceDoor(
        sn: 'SN-001',
        doorId: '7',
        doorType: 0,
        requestId: 'request-2',
      ),
      throwsA(
        isA<AddDeviceOnboardingRemoteException>()
            .having((error) => error.serverCode, 'serverCode', 100408)
            .having(
              (error) => error.serverMessageKey,
              'serverMessageKey',
              'app.door.device_not_exists',
            ),
      ),
    );
  });
}

class _FakeAddDeviceOnboardingApi implements AddDeviceOnboardingApi {
  _FakeAddDeviceOnboardingApi({
    this.bindingStatusResponse,
    this.deviceKeyResponse,
    this.addDoorResponse,
  });

  final ApiEnvelopeDto<OnboardingDeviceKeyResponseDto>? deviceKeyResponse;
  final ApiEnvelopeDto<ForceDoorResponseDto>? addDoorResponse;
  final ApiEnvelopeDto<BindingStatusResponseDto>? bindingStatusResponse;
  AddForceDoorRequestDto? lastAddForceDoorRequest;
  Options? lastAddForceDoorOptions;

  @override
  Future<ApiEnvelopeDto<BindingStatusResponseDto>> validateBindingStatus(
    String sn,
    Options options,
  ) async {
    return bindingStatusResponse ??
        const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: BindingStatusResponseDto(
            sn: 'SN-001',
            bound: false,
            ownedByCurrentUser: false,
            canBind: true,
          ),
        );
  }

  @override
  Future<ApiEnvelopeDto<OnboardingDeviceKeyResponseDto>> fetchDeviceKey(
    String sn,
    Options options,
  ) async {
    return deviceKeyResponse ??
        const ApiEnvelopeDto(
          code: 0,
          success: true,
          data: OnboardingDeviceKeyResponseDto(
            sn: 'SN-001',
            aesKey: '0123456789abcdef0123456789abcdef',
            aesKeyVersion: 'v1',
          ),
        );
  }

  @override
  Future<ApiEnvelopeDto<ForceDoorResponseDto>> addForceDoor(
    AddForceDoorRequestDto request,
    Options options,
  ) async {
    lastAddForceDoorRequest = request;
    lastAddForceDoorOptions = options;
    return addDoorResponse ??
        const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: ForceDoorResponseDto(id: 1),
        );
  }
}
