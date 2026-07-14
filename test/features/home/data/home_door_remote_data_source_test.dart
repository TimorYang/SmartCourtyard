import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/home/data/data_sources/home_api.dart';
import 'package:flinx/features/home/data/data_sources/home_door_remote_data_source.dart';
import 'package:flinx/features/home/data/dto/create_home_scene_request_dto.dart';
import 'package:flinx/features/home/data/dto/home_door_response_dto.dart';
import 'package:flinx/features/home/data/dto/home_scene_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses door dto fields and ignores unknown fields', () {
    final dto = HomeDoorResponseDto.fromJson(const {
      'id': '12',
      'name': 'Main Gate',
      'sceneId': '7',
      'onlineStatus': '1',
      'onlineStatusLabel': '在线',
      'doorState': '4',
      'doorStateLabel': '正在关门',
      'positionPercent': '68.5',
      'top': true,
      'ignored': 'value',
    });

    expect(dto.id, 12);
    expect(dto.name, 'Main Gate');
    expect(dto.sceneId, 7);
    expect(dto.onlineStatus, 1);
    expect(dto.onlineStatusLabel, '在线');
    expect(dto.doorState, 4);
    expect(dto.doorStateLabel, '正在关门');
    expect(dto.positionPercent, 68.5);
    expect(dto.top, isTrue);
  });

  test('fetches doors with scene id and request id', () async {
    final api = _FakeHomeApi(
      doorResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: [
          HomeDoorResponseDto(
            id: 12,
            name: 'Main Gate',
            sceneId: 7,
            onlineStatus: 1,
            onlineStatusLabel: '在线',
            doorState: 1,
            doorStateLabel: '开启',
          ),
        ],
      ),
    );
    final dataSource = HomeDoorRemoteDataSourceImpl(api: api);

    final doors = await dataSource.fetchDoors(
      sceneId: 7,
      requestId: 'home-doors-123',
    );

    expect(doors, hasLength(1));
    expect(doors.single.name, 'Main Gate');
    expect(api.sceneId, 7);
    expect(
      api.options.extra?[NetworkRequestExtras.requestId],
      'home-doors-123',
    );
  });

  test('rejects code 0 response', () async {
    final dataSource = HomeDoorRemoteDataSourceImpl(
      api: _FakeHomeApi(
        doorResponse: const ApiEnvelopeDto(
          code: 0,
          success: true,
          data: <HomeDoorResponseDto>[],
        ),
      ),
    );

    await expectLater(
      dataSource.fetchDoors(sceneId: 7, requestId: 'home-doors-123'),
      throwsA(isA<HomeDoorRemoteException>()),
    );
  });

  test('tops a door with request id', () async {
    final api = _FakeHomeApi(
      doorResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: <HomeDoorResponseDto>[],
      ),
      topResponse: const ApiEnvelopeDto(code: 200, success: true, data: true),
    );
    final dataSource = HomeDoorRemoteDataSourceImpl(api: api);

    await dataSource.topDoor(doorId: 12, requestId: 'home-top-door-123');

    expect(api.topDoorId, 12);
    expect(
      api.topOptions.extra?[NetworkRequestExtras.requestId],
      'home-top-door-123',
    );
  });

  test('rejects unsuccessful business response', () async {
    final dataSource = HomeDoorRemoteDataSourceImpl(
      api: _FakeHomeApi(
        doorResponse: const ApiEnvelopeDto<List<HomeDoorResponseDto>>(
          code: 500,
          success: false,
        ),
      ),
    );

    expect(
      () => dataSource.fetchDoors(sceneId: 7, requestId: 'home-doors-123'),
      throwsA(
        isA<HomeDoorRemoteException>().having(
          (error) => error.kind,
          'kind',
          HomeDoorRemoteErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('converts DioException to remote network exception', () async {
    final dataSource = HomeDoorRemoteDataSourceImpl(
      api: _ThrowingHomeApi(
        DioException(
          requestOptions: RequestOptions(path: 'app/doors'),
          type: DioExceptionType.connectionError,
          error: 'offline',
        ),
      ),
    );

    expect(
      () => dataSource.fetchDoors(sceneId: 7, requestId: 'home-doors-123'),
      throwsA(
        isA<HomeDoorRemoteException>().having(
          (error) => error.kind,
          'kind',
          HomeDoorRemoteErrorKind.network,
        ),
      ),
    );
  });
}

class _FakeHomeApi implements HomeApi {
  _FakeHomeApi({required this.doorResponse, this.topResponse});

  final ApiEnvelopeDto<List<HomeDoorResponseDto>> doorResponse;
  final ApiEnvelopeDto<bool>? topResponse;
  late final Options options;
  late final int sceneId;
  late final Options topOptions;
  late final int topDoorId;

  @override
  Future<ApiEnvelopeDto<bool>> topDoor(
    int doorId,
    Options requestOptions,
  ) async {
    topDoorId = doorId;
    topOptions = requestOptions;
    return topResponse ??
        const ApiEnvelopeDto<bool>(code: 200, success: true, data: true);
  }

  @override
  Future<ApiEnvelopeDto<List<HomeDoorResponseDto>>> fetchDoors(
    int sceneId,
    Options requestOptions,
  ) async {
    this.sceneId = sceneId;
    options = requestOptions;
    return doorResponse;
  }

  @override
  Future<ApiEnvelopeDto<List<HomeSceneResponseDto>>> fetchScenes(
    Options options,
  ) async {
    return const ApiEnvelopeDto<List<HomeSceneResponseDto>>(
      code: 0,
      success: true,
      data: <HomeSceneResponseDto>[],
    );
  }

  @override
  Future<ApiEnvelopeDto<HomeSceneResponseDto>> createScene(
    CreateHomeSceneRequestDto request,
    Options options,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> deleteScene(int sceneId, Options options) {
    throw UnimplementedError();
  }

  @override
  Future<ApiEnvelopeDto<bool>> renameScene(
    int sceneId,
    CreateHomeSceneRequestDto request,
    Options options,
  ) {
    throw UnimplementedError();
  }
}

class _ThrowingHomeApi implements HomeApi {
  const _ThrowingHomeApi(this.error);

  final DioException error;

  @override
  Future<ApiEnvelopeDto<bool>> topDoor(int doorId, Options options) {
    throw error;
  }

  @override
  Future<ApiEnvelopeDto<List<HomeDoorResponseDto>>> fetchDoors(
    int sceneId,
    Options options,
  ) {
    throw error;
  }

  @override
  Future<ApiEnvelopeDto<List<HomeSceneResponseDto>>> fetchScenes(
    Options options,
  ) {
    throw error;
  }

  @override
  Future<ApiEnvelopeDto<HomeSceneResponseDto>> createScene(
    CreateHomeSceneRequestDto request,
    Options options,
  ) {
    throw error;
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> deleteScene(int sceneId, Options options) {
    throw error;
  }

  @override
  Future<ApiEnvelopeDto<bool>> renameScene(
    int sceneId,
    CreateHomeSceneRequestDto request,
    Options options,
  ) {
    throw error;
  }
}
