import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/device_control/data/data_sources/door_control_mode_api.dart';
import 'package:flinx/features/device_control/data/data_sources/door_control_mode_remote_data_source.dart';
import 'package:flinx/features/device_control/data/dto/update_door_control_mode_request_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports PB as string 0 with request correlation', () async {
    final api = _FakeDoorControlModeApi(
      response: const ApiEnvelopeDto<dynamic>(
        code: 200,
        success: true,
        data: <String, dynamic>{},
      ),
    );
    final dataSource = DoorControlModeRemoteDataSourceImpl(api: api);

    await dataSource.updateControlMode(
      sn: 'SN-PB',
      controlMode: '0',
      requestId: 'fbox-control-mode-pb',
    );

    expect(api.request.toJson(), {'sn': 'SN-PB', 'controlMode': '0'});
    expect(
      api.options.extra?[NetworkRequestExtras.requestId],
      'fbox-control-mode-pb',
    );
  });

  test('reports OSC as string 1', () async {
    final api = _FakeDoorControlModeApi(
      response: const ApiEnvelopeDto<dynamic>(
        code: 200,
        success: true,
        data: <String, dynamic>{},
      ),
    );
    final dataSource = DoorControlModeRemoteDataSourceImpl(api: api);

    await dataSource.updateControlMode(
      sn: 'SN-OSC',
      controlMode: '1',
      requestId: 'fbox-control-mode-osc',
    );

    expect(api.request.toJson(), {'sn': 'SN-OSC', 'controlMode': '1'});
  });

  test('accepts code 200 and success true without validating data', () async {
    final dataSource = DoorControlModeRemoteDataSourceImpl(
      api: _FakeDoorControlModeApi(
        response: const ApiEnvelopeDto<dynamic>(
          code: 200,
          success: true,
          data: <String, dynamic>{},
        ),
      ),
    );

    await dataSource.updateControlMode(
      sn: 'SN-EMPTY-DATA',
      controlMode: '0',
      requestId: 'fbox-control-mode-empty-data',
    );
  });

  test('rejects a response with code 0', () async {
    final dataSource = DoorControlModeRemoteDataSourceImpl(
      api: _FakeDoorControlModeApi(
        response: const ApiEnvelopeDto<dynamic>(
          code: 0,
          success: true,
          data: <String, dynamic>{},
        ),
      ),
    );

    await expectLater(
      dataSource.updateControlMode(
        sn: 'SN-001',
        controlMode: '0',
        requestId: 'fbox-control-mode-code-zero',
      ),
      throwsA(
        isA<DoorControlModeRemoteException>().having(
          (error) => error.kind,
          'kind',
          DoorControlModeRemoteErrorKind.businessFailure,
        ),
      ),
    );
  });

  test('rejects a response with success false', () async {
    final dataSource = DoorControlModeRemoteDataSourceImpl(
      api: _FakeDoorControlModeApi(
        response: const ApiEnvelopeDto<dynamic>(
          code: 200,
          success: false,
          data: <String, dynamic>{},
        ),
      ),
    );

    await expectLater(
      dataSource.updateControlMode(
        sn: 'SN-001',
        controlMode: '1',
        requestId: 'fbox-control-mode-unsuccessful',
      ),
      throwsA(
        isA<DoorControlModeRemoteException>().having(
          (error) => error.kind,
          'kind',
          DoorControlModeRemoteErrorKind.businessFailure,
        ),
      ),
    );
  });

  test('converts DioException to a remote network exception', () async {
    final dataSource = DoorControlModeRemoteDataSourceImpl(
      api: _ThrowingDoorControlModeApi(
        DioException(
          requestOptions: RequestOptions(path: 'app/doors/control-mode'),
          type: DioExceptionType.connectionError,
        ),
      ),
    );

    expect(
      () => dataSource.updateControlMode(
        sn: 'SN-001',
        controlMode: '0',
        requestId: 'fbox-control-mode-network',
      ),
      throwsA(
        isA<DoorControlModeRemoteException>().having(
          (error) => error.kind,
          'kind',
          DoorControlModeRemoteErrorKind.network,
        ),
      ),
    );
  });
}

class _FakeDoorControlModeApi implements DoorControlModeApi {
  _FakeDoorControlModeApi({required this.response});

  final ApiEnvelopeDto<dynamic> response;
  late UpdateDoorControlModeRequestDto request;
  late Options options;

  @override
  Future<ApiEnvelopeDto<dynamic>> updateControlMode(
    UpdateDoorControlModeRequestDto request,
    Options options,
  ) async {
    this.request = request;
    this.options = options;
    return response;
  }
}

class _ThrowingDoorControlModeApi implements DoorControlModeApi {
  const _ThrowingDoorControlModeApi(this.error);

  final DioException error;

  @override
  Future<ApiEnvelopeDto<dynamic>> updateControlMode(
    UpdateDoorControlModeRequestDto request,
    Options options,
  ) {
    throw error;
  }
}
