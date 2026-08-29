import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/home/data/data_sources/home_api.dart';
import 'package:flinx/features/home/data/data_sources/home_door_remote_data_source.dart';
import 'package:flinx/features/home/data/dto/create_home_scene_request_dto.dart';
import 'package:flinx/features/home/data/dto/home_door_response_dto.dart';
import 'package:flinx/features/home/data/dto/home_scene_response_dto.dart';
import 'package:flinx/features/home/data/dto/move_home_door_scene_request_dto.dart';
import 'package:flinx/features/home/data/dto/rename_home_door_request_dto.dart';
import 'package:flinx/features/home/data/dto/attachment_upload_result_dto.dart';
import 'package:flinx/features/home/data/dto/update_home_door_cover_request_dto.dart';
import 'package:flinx/features/home/domain/entities/home_door_cover_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes move door scene request dto', () {
    final dto = MoveHomeDoorSceneRequestDto.fromJson(const {'sceneId': '8'});

    expect(dto.sceneId, 8);
    expect(dto.toJson(), {'sceneId': 8});
  });

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
      'shareStatus': '2',
      'shareStatusLabel': 'Sharing',
      'hasBoundDevices': true,
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
    expect(dto.shareStatus, 2);
    expect(dto.shareStatusLabel, 'Sharing');
    expect(dto.hasBoundDevices, isTrue);
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

  test('unbinds a door with request id', () async {
    final api = _FakeHomeApi(
      doorResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: <HomeDoorResponseDto>[],
      ),
      unbindResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: true,
      ),
    );
    final dataSource = HomeDoorRemoteDataSourceImpl(api: api);

    await dataSource.unbindDoor(doorId: 12, requestId: 'home-unbind-door-123');

    expect(api.unbindDoorId, 12);
    expect(
      api.unbindOptions.extra?[NetworkRequestExtras.requestId],
      'home-unbind-door-123',
    );
  });

  test('resets a door cover with request id', () async {
    final api = _FakeHomeApi(
      doorResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: <HomeDoorResponseDto>[],
      ),
      resetCoverResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: true,
      ),
    );
    final dataSource = HomeDoorRemoteDataSourceImpl(api: api);

    await dataSource.resetDoorCover(
      doorId: 12,
      requestId: 'home-reset-door-cover-123',
    );

    expect(api.resetCoverDoorId, 12);
    expect(
      api.resetCoverOptions.extra?[NetworkRequestExtras.requestId],
      'home-reset-door-cover-123',
    );
  });

  test(
    'uploads an image then updates the door cover with one request id',
    () async {
      final api = _FakeHomeApi(
        doorResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: <HomeDoorResponseDto>[],
        ),
        uploadCoverResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: AttachmentUploadResultDto(fileId: 30001),
        ),
        updateCoverResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: true,
        ),
      );
      final dataSource = HomeDoorRemoteDataSourceImpl(api: api);

      await dataSource.updateDoorCover(
        doorId: 12,
        image: HomeDoorCoverImage(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'cover.jpg',
        ),
        requestId: 'home-update-door-cover-12-123',
      );

      expect(api.callOrder, ['upload', 'update']);
      expect(api.uploadFormData.fields, isEmpty);
      expect(api.uploadFormData.files.single.key, 'file');
      expect(api.uploadFormData.files.single.value.filename, 'cover.jpg');
      expect(
        api.uploadOptions.contentType,
        Headers.multipartFormDataContentType,
      );
      expect(
        api.uploadOptions.extra?[NetworkRequestExtras.requestId],
        'home-update-door-cover-12-123',
      );
      expect(api.updateCoverDoorId, 12);
      expect(api.updateCoverRequest.toJson(), {'coverFileId': 30001});
      expect(
        api.updateCoverOptions.extra?[NetworkRequestExtras.requestId],
        'home-update-door-cover-12-123',
      );
    },
  );

  test('does not update a door cover when image upload fails', () async {
    final api = _FakeHomeApi(
      doorResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: <HomeDoorResponseDto>[],
      ),
      uploadCoverResponse: const ApiEnvelopeDto(code: 200, success: true),
    );

    await expectLater(
      HomeDoorRemoteDataSourceImpl(api: api).updateDoorCover(
        doorId: 12,
        image: HomeDoorCoverImage(
          bytes: Uint8List.fromList([1]),
          fileName: 'cover.jpg',
        ),
        requestId: 'home-update-door-cover-12-123',
      ),
      throwsA(isA<HomeDoorRemoteException>()),
    );
    expect(api.callOrder, ['upload']);
  });

  test('renames a door with request body and request id', () async {
    final api = _FakeHomeApi(
      doorResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: <HomeDoorResponseDto>[],
      ),
      renameDoorResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: true,
      ),
    );
    final dataSource = HomeDoorRemoteDataSourceImpl(api: api);

    await dataSource.renameDoor(
      doorId: 12,
      name: 'Garage Door',
      requestId: 'home-rename-door-123',
    );

    expect(api.renameDoorId, 12);
    expect(api.renameDoorRequest.name, 'Garage Door');
    expect(
      api.renameDoorOptions.extra?[NetworkRequestExtras.requestId],
      'home-rename-door-123',
    );
  });

  test('moves a door to a scene with request body and request id', () async {
    final api = _FakeHomeApi(
      doorResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: <HomeDoorResponseDto>[],
      ),
      moveDoorToSceneResponse: const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: true,
      ),
    );
    final dataSource = HomeDoorRemoteDataSourceImpl(api: api);

    await dataSource.moveDoorToScene(
      doorId: 12,
      sceneId: 8,
      requestId: 'home-move-door-12-to-8',
    );

    expect(api.moveDoorId, 12);
    expect(api.moveDoorRequest.toJson(), {'sceneId': 8});
    expect(
      api.moveDoorOptions.extra?[NetworkRequestExtras.requestId],
      'home-move-door-12-to-8',
    );
  });

  test('rejects an unsuccessful move response', () async {
    final dataSource = HomeDoorRemoteDataSourceImpl(
      api: _FakeHomeApi(
        doorResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: <HomeDoorResponseDto>[],
        ),
        moveDoorToSceneResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: false,
        ),
      ),
    );

    await expectLater(
      dataSource.moveDoorToScene(
        doorId: 12,
        sceneId: 8,
        requestId: 'home-move-door-12-to-8',
      ),
      throwsA(isA<HomeDoorRemoteException>()),
    );
  });

  test('rejects unsuccessful reset cover response', () async {
    final dataSource = HomeDoorRemoteDataSourceImpl(
      api: _FakeHomeApi(
        doorResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: <HomeDoorResponseDto>[],
        ),
        resetCoverResponse: const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: false,
        ),
      ),
    );

    await expectLater(
      dataSource.resetDoorCover(
        doorId: 12,
        requestId: 'home-reset-door-cover-123',
      ),
      throwsA(
        isA<HomeDoorRemoteException>().having(
          (error) => error.kind,
          'kind',
          HomeDoorRemoteErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('rejects unsuccessful business response', () async {
    final dataSource = HomeDoorRemoteDataSourceImpl(
      api: _FakeHomeApi(
        doorResponse: const ApiEnvelopeDto<List<HomeDoorResponseDto>>(
          code: 500,
          success: false,
          msg: 'Unable to load doors',
        ),
      ),
    );

    expect(
      () => dataSource.fetchDoors(sceneId: 7, requestId: 'home-doors-123'),
      throwsA(
        isA<HomeDoorRemoteException>()
            .having(
              (error) => error.kind,
              'kind',
              HomeDoorRemoteErrorKind.businessFailure,
            )
            .having(
              (error) => error.businessFailure?.message,
              'message',
              'Unable to load doors',
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
  _FakeHomeApi({
    required this.doorResponse,
    this.topResponse,
    this.unbindResponse,
    this.resetCoverResponse,
    this.renameDoorResponse,
    this.moveDoorToSceneResponse,
    this.uploadCoverResponse,
    this.updateCoverResponse,
  });

  final ApiEnvelopeDto<List<HomeDoorResponseDto>> doorResponse;
  final ApiEnvelopeDto<bool>? topResponse;
  final ApiEnvelopeDto<bool>? unbindResponse;
  final ApiEnvelopeDto<bool>? resetCoverResponse;
  final ApiEnvelopeDto<bool>? renameDoorResponse;
  final ApiEnvelopeDto<bool>? moveDoorToSceneResponse;
  final ApiEnvelopeDto<AttachmentUploadResultDto>? uploadCoverResponse;
  final ApiEnvelopeDto<bool>? updateCoverResponse;
  final callOrder = <String>[];
  late FormData uploadFormData;
  late Options uploadOptions;
  late int updateCoverDoorId;
  late UpdateHomeDoorCoverRequestDto updateCoverRequest;
  late Options updateCoverOptions;
  late final Options options;
  late final int sceneId;
  late final Options topOptions;
  late final int topDoorId;
  late final Options unbindOptions;
  late final int unbindDoorId;
  late final Options resetCoverOptions;
  late final int resetCoverDoorId;
  late final Options renameDoorOptions;
  late final int renameDoorId;
  late final RenameHomeDoorRequestDto renameDoorRequest;
  late final Options moveDoorOptions;
  late final int moveDoorId;
  late final MoveHomeDoorSceneRequestDto moveDoorRequest;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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
  Future<ApiEnvelopeDto<bool>> unbindDoor(
    int doorId,
    Options requestOptions,
  ) async {
    unbindDoorId = doorId;
    unbindOptions = requestOptions;
    return unbindResponse ??
        const ApiEnvelopeDto<bool>(code: 200, success: true, data: true);
  }

  @override
  Future<ApiEnvelopeDto<bool>> resetDoorCover(
    int doorId,
    Options requestOptions,
  ) async {
    resetCoverDoorId = doorId;
    resetCoverOptions = requestOptions;
    return resetCoverResponse ??
        const ApiEnvelopeDto<bool>(code: 200, success: true, data: true);
  }

  @override
  Future<ApiEnvelopeDto<AttachmentUploadResultDto>> uploadDoorCoverImage(
    FormData formData,
    Options requestOptions,
  ) async {
    callOrder.add('upload');
    uploadFormData = formData;
    uploadOptions = requestOptions;
    return uploadCoverResponse ??
        const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: AttachmentUploadResultDto(fileId: 1),
        );
  }

  @override
  Future<ApiEnvelopeDto<bool>> updateDoorCover(
    int doorId,
    UpdateHomeDoorCoverRequestDto request,
    Options requestOptions,
  ) async {
    callOrder.add('update');
    updateCoverDoorId = doorId;
    updateCoverRequest = request;
    updateCoverOptions = requestOptions;
    return updateCoverResponse ??
        const ApiEnvelopeDto(code: 200, success: true, data: true);
  }

  @override
  Future<ApiEnvelopeDto<bool>> renameDoor(
    int doorId,
    RenameHomeDoorRequestDto request,
    Options requestOptions,
  ) async {
    renameDoorId = doorId;
    renameDoorRequest = request;
    renameDoorOptions = requestOptions;
    return renameDoorResponse ??
        const ApiEnvelopeDto<bool>(code: 200, success: true, data: true);
  }

  @override
  Future<ApiEnvelopeDto<bool>> moveDoorToScene(
    int doorId,
    MoveHomeDoorSceneRequestDto request,
    Options requestOptions,
  ) async {
    moveDoorId = doorId;
    moveDoorRequest = request;
    moveDoorOptions = requestOptions;
    return moveDoorToSceneResponse ??
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ApiEnvelopeDto<bool>> topDoor(int doorId, Options options) {
    throw error;
  }

  @override
  Future<ApiEnvelopeDto<bool>> unbindDoor(int doorId, Options options) {
    throw error;
  }

  @override
  Future<ApiEnvelopeDto<bool>> resetDoorCover(int doorId, Options options) {
    throw error;
  }

  @override
  Future<ApiEnvelopeDto<AttachmentUploadResultDto>> uploadDoorCoverImage(
    FormData formData,
    Options options,
  ) {
    throw error;
  }

  @override
  Future<ApiEnvelopeDto<bool>> updateDoorCover(
    int doorId,
    UpdateHomeDoorCoverRequestDto request,
    Options options,
  ) {
    throw error;
  }

  @override
  Future<ApiEnvelopeDto<bool>> renameDoor(
    int doorId,
    RenameHomeDoorRequestDto request,
    Options options,
  ) {
    throw error;
  }

  @override
  Future<ApiEnvelopeDto<bool>> moveDoorToScene(
    int doorId,
    MoveHomeDoorSceneRequestDto request,
    Options options,
  ) {
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
