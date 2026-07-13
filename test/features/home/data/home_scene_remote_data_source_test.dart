import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/home/data/data_sources/home_api.dart';
import 'package:flinx/features/home/data/data_sources/home_scene_remote_data_source.dart';
import 'package:flinx/features/home/data/dto/create_home_scene_request_dto.dart';
import 'package:flinx/features/home/data/dto/home_scene_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses scene dto fields and ignores unknown fields', () {
    final dto = HomeSceneResponseDto.fromJson(const {
      'defaultScene': true,
      'doorCount': '2',
      'id': '7',
      'name': 'Garage',
      'ignored': 'value',
    });

    expect(dto.defaultScene, isTrue);
    expect(dto.doorCount, 2);
    expect(dto.id, 7);
    expect(dto.name, 'Garage');
  });

  test(
    'fetches scenes with request id and accepts code 200 response',
    () async {
      final api = _FakeHomeApi(
        fetchResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: [
            HomeSceneResponseDto(
              defaultScene: true,
              doorCount: 1,
              id: 1,
              name: 'Home',
            ),
          ],
        ),
      );
      final dataSource = HomeSceneRemoteDataSourceImpl(api: api);

      final scenes = await dataSource.fetchScenes(requestId: 'home-scenes-123');

      expect(scenes, hasLength(1));
      expect(scenes.single.name, 'Home');
      expect(
        api.options.extra?[NetworkRequestExtras.requestId],
        'home-scenes-123',
      );
    },
  );

  test('creates scene with request body and request id', () async {
    final api = _FakeHomeApi(
      createResponse: const ApiEnvelopeDto(
        code: 0,
        success: true,
        data: HomeSceneResponseDto(
          defaultScene: false,
          doorCount: 0,
          id: 8,
          name: 'Garage',
        ),
      ),
    );
    final dataSource = HomeSceneRemoteDataSourceImpl(api: api);

    final scene = await dataSource.createScene(
      name: 'Garage',
      requestId: 'home-create-scene-123',
    );

    expect(scene.id, 8);
    expect(scene.name, 'Garage');
    expect(api.createRequest.name, 'Garage');
    expect(
      api.options.extra?[NetworkRequestExtras.requestId],
      'home-create-scene-123',
    );
  });

  test('rejects unsuccessful create scene response', () async {
    final dataSource = HomeSceneRemoteDataSourceImpl(
      api: _FakeHomeApi(
        createResponse: const ApiEnvelopeDto<HomeSceneResponseDto>(
          code: 500,
          success: false,
        ),
      ),
    );

    expect(
      () => dataSource.createScene(
        name: 'Garage',
        requestId: 'home-create-scene-123',
      ),
      throwsA(
        isA<HomeSceneRemoteException>().having(
          (error) => error.kind,
          'kind',
          HomeSceneRemoteErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('rejects unsuccessful business response', () async {
    final dataSource = HomeSceneRemoteDataSourceImpl(
      api: _FakeHomeApi(
        fetchResponse: const ApiEnvelopeDto<List<HomeSceneResponseDto>>(
          code: 0,
          success: false,
        ),
      ),
    );

    expect(
      () => dataSource.fetchScenes(requestId: 'home-scenes-123'),
      throwsA(
        isA<HomeSceneRemoteException>().having(
          (error) => error.kind,
          'kind',
          HomeSceneRemoteErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('converts DioException to remote network exception', () async {
    final dataSource = HomeSceneRemoteDataSourceImpl(
      api: _ThrowingHomeApi(
        DioException(
          requestOptions: RequestOptions(path: 'app/scenes'),
          type: DioExceptionType.connectionError,
          error: 'offline',
        ),
      ),
    );

    expect(
      () => dataSource.fetchScenes(requestId: 'home-scenes-123'),
      throwsA(
        isA<HomeSceneRemoteException>().having(
          (error) => error.kind,
          'kind',
          HomeSceneRemoteErrorKind.network,
        ),
      ),
    );
  });
}

class _FakeHomeApi implements HomeApi {
  _FakeHomeApi({this.fetchResponse, this.createResponse});

  final ApiEnvelopeDto<List<HomeSceneResponseDto>>? fetchResponse;
  final ApiEnvelopeDto<HomeSceneResponseDto>? createResponse;
  late Options options;
  late CreateHomeSceneRequestDto createRequest;

  @override
  Future<ApiEnvelopeDto<List<HomeSceneResponseDto>>> fetchScenes(
    Options requestOptions,
  ) async {
    options = requestOptions;
    return fetchResponse!;
  }

  @override
  Future<ApiEnvelopeDto<HomeSceneResponseDto>> createScene(
    CreateHomeSceneRequestDto request,
    Options requestOptions,
  ) async {
    createRequest = request;
    options = requestOptions;
    return createResponse!;
  }
}

class _ThrowingHomeApi implements HomeApi {
  const _ThrowingHomeApi(this.error);

  final DioException error;

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
}
