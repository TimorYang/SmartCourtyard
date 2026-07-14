import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/features/add_device/data/data_sources/add_device_onboarding_api.dart';
import 'package:flinx/features/add_device/data/data_sources/add_device_onboarding_remote_data_source.dart';
import 'package:flinx/features/add_device/data/dto/add_force_door_request_dto.dart';
import 'package:flinx/features/add_device/data/dto/force_door_response_dto.dart';
import 'package:flinx/features/add_device/data/dto/onboarding_device_key_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    final dataSource = AddDeviceOnboardingRemoteDataSourceImpl(
      api: _FakeAddDeviceOnboardingApi(
        addDoorResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: ForceDoorResponseDto(
            id: 7,
            hardwareSn: 'SN-001',
            name: 'Garage door',
          ),
        ),
      ),
    );

    final result = await dataSource.addForceDoor(
      sn: 'SN-001',
      requestId: 'request-2',
    );

    expect(result.id, 7);
    expect(result.hardwareSn, 'SN-001');
  });

  test('addForceDoor rejects failed envelope', () async {
    final dataSource = AddDeviceOnboardingRemoteDataSourceImpl(
      api: _FakeAddDeviceOnboardingApi(
        addDoorResponse: const ApiEnvelopeDto(
          code: 500,
          success: false,
          data: ForceDoorResponseDto(id: 7, hardwareSn: 'SN-001'),
        ),
      ),
    );

    expect(
      () => dataSource.addForceDoor(sn: 'SN-001', requestId: 'request-2'),
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
      () => dataSource.addForceDoor(sn: 'SN-001', requestId: 'request-2'),
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
  const _FakeAddDeviceOnboardingApi({
    this.deviceKeyResponse,
    this.addDoorResponse,
  });

  final ApiEnvelopeDto<OnboardingDeviceKeyResponseDto>? deviceKeyResponse;
  final ApiEnvelopeDto<ForceDoorResponseDto>? addDoorResponse;

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
    return addDoorResponse ??
        const ApiEnvelopeDto(
          code: 0,
          success: true,
          data: ForceDoorResponseDto(id: 1, hardwareSn: 'SN-001'),
        );
  }
}
