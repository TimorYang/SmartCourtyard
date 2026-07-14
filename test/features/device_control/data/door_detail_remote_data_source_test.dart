import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/device_control/data/data_sources/door_detail_api.dart';
import 'package:flinx/features/device_control/data/data_sources/door_detail_remote_data_source.dart';
import 'package:flinx/features/device_control/data/dto/door_detail_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses door detail dto fields and ignores unknown fields', () {
    final dto = DoorDetailResponseDto.fromJson(const {
      'id': '12',
      'name': 'Main Gate',
      'sceneId': '7',
      'onlineStatus': '1',
      'doorState': '2',
      'doorStateLabel': 'Closed',
      'positionPercent': '68.5',
      'operatedCycles': '123',
      'remainingCycles': '4567',
      'hardwareSn': 'SN-001',
      'ignored': 'value',
    });

    expect(dto.id, 12);
    expect(dto.name, 'Main Gate');
    expect(dto.sceneId, 7);
    expect(dto.onlineStatus, 1);
    expect(dto.doorState, 2);
    expect(dto.doorStateLabel, 'Closed');
    expect(dto.positionPercent, 68.5);
    expect(dto.operatedCycles, 123);
    expect(dto.remainingCycles, 4567);
    expect(dto.hardwareSn, 'SN-001');
  });

  test('fetches door detail with door id and request id', () async {
    final api = _FakeDoorDetailApi(
      response: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: DoorDetailResponseDto(
          id: 12,
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
          data: DoorDetailResponseDto(id: 12, name: 'Main Gate'),
        ),
      ),
    );

    final detail = await dataSource.fetchDoorDetail(
      doorId: 12,
      requestId: 'door-detail-123',
    );

    expect(detail.id, 12);
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
  _FakeDoorDetailApi({required this.response});

  final ApiEnvelopeDto<DoorDetailResponseDto> response;
  late int doorId;
  late Options options;

  @override
  Future<ApiEnvelopeDto<DoorDetailResponseDto>> fetchDoorDetail(
    int doorId,
    Options options,
  ) async {
    this.doorId = doorId;
    this.options = options;
    return response;
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
}
