import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/home_door_response_dto.dart';
import '../dto/move_home_door_scene_request_dto.dart';
import '../dto/rename_home_door_request_dto.dart';
import '../dto/update_home_door_cover_request_dto.dart';
import '../../domain/entities/home_door_cover_image.dart';
import 'home_api.dart';

abstract interface class HomeDoorRemoteDataSource {
  Future<List<HomeDoorResponseDto>> fetchDoors({
    required int sceneId,
    required String requestId,
  });

  Future<void> topDoor({required int doorId, required String requestId});

  Future<void> unbindDoor({required int doorId, required String requestId});

  Future<void> resetDoorCover({required int doorId, required String requestId});

  Future<void> updateDoorCover({
    required int doorId,
    required HomeDoorCoverImage image,
    required String requestId,
  });

  Future<void> renameDoor({
    required int doorId,
    required String name,
    required String requestId,
  });

  Future<void> moveDoorToScene({
    required int doorId,
    required int sceneId,
    required String requestId,
  });
}

class HomeDoorRemoteDataSourceImpl implements HomeDoorRemoteDataSource {
  const HomeDoorRemoteDataSourceImpl({required this.api});

  final HomeApi api;

  @override
  Future<List<HomeDoorResponseDto>> fetchDoors({
    required int sceneId,
    required String requestId,
  }) async {
    try {
      final response = await api.fetchDoors(
        sceneId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (!_isSuccessCode(response.code) || !response.success || data == null) {
        throw const HomeDoorRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw HomeDoorRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on HomeDoorRemoteException {
      rethrow;
    }
  }

  @override
  Future<void> topDoor({required int doorId, required String requestId}) async {
    try {
      final response = await api.topDoor(
        doorId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!_isSuccessCode(response.code) || !response.success) {
        throw const HomeDoorRemoteException.invalidResponse();
      }
    } on DioException catch (error) {
      throw HomeDoorRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on HomeDoorRemoteException {
      rethrow;
    }
  }

  @override
  Future<void> unbindDoor({
    required int doorId,
    required String requestId,
  }) async {
    try {
      final response = await api.unbindDoor(
        doorId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!_isSuccessCode(response.code) || !response.success) {
        throw const HomeDoorRemoteException.invalidResponse();
      }
    } on DioException catch (error) {
      throw HomeDoorRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on HomeDoorRemoteException {
      rethrow;
    }
  }

  @override
  Future<void> resetDoorCover({
    required int doorId,
    required String requestId,
  }) async {
    try {
      final response = await api.resetDoorCover(
        doorId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!_isSuccessCode(response.code) ||
          !response.success ||
          response.data != true) {
        throw const HomeDoorRemoteException.invalidResponse();
      }
    } on DioException catch (error) {
      throw HomeDoorRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on HomeDoorRemoteException {
      rethrow;
    }
  }

  @override
  Future<void> updateDoorCover({
    required int doorId,
    required HomeDoorCoverImage image,
    required String requestId,
  }) async {
    try {
      final uploadResponse = await api.uploadDoorCoverImage(
        FormData.fromMap({
          'file': MultipartFile.fromBytes(
            image.bytes,
            filename: image.fileName,
          ),
        }),
        Options(
          contentType: Headers.multipartFormDataContentType,
          extra: {NetworkRequestExtras.requestId: requestId},
        ),
      );
      final uploadResult = uploadResponse.data;
      if (!_isSuccessCode(uploadResponse.code) ||
          !uploadResponse.success ||
          uploadResult == null ||
          uploadResult.fileId <= 0) {
        throw const HomeDoorRemoteException.invalidResponse();
      }

      final coverResponse = await api.updateDoorCover(
        doorId,
        UpdateHomeDoorCoverRequestDto(coverFileId: uploadResult.fileId),
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!_isSuccessCode(coverResponse.code) ||
          !coverResponse.success ||
          coverResponse.data != true) {
        throw const HomeDoorRemoteException.invalidResponse();
      }
    } on DioException catch (error) {
      throw HomeDoorRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on HomeDoorRemoteException {
      rethrow;
    }
  }

  @override
  Future<void> renameDoor({
    required int doorId,
    required String name,
    required String requestId,
  }) async {
    try {
      final response = await api.renameDoor(
        doorId,
        RenameHomeDoorRequestDto(name: name),
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!_isSuccessCode(response.code) ||
          !response.success ||
          response.data != true) {
        throw const HomeDoorRemoteException.invalidResponse();
      }
    } on DioException catch (error) {
      throw HomeDoorRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on HomeDoorRemoteException {
      rethrow;
    }
  }

  @override
  Future<void> moveDoorToScene({
    required int doorId,
    required int sceneId,
    required String requestId,
  }) async {
    try {
      final response = await api.moveDoorToScene(
        doorId,
        MoveHomeDoorSceneRequestDto(sceneId: sceneId),
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!_isSuccessCode(response.code) ||
          !response.success ||
          response.data != true) {
        throw const HomeDoorRemoteException.invalidResponse();
      }
    } on DioException catch (error) {
      throw HomeDoorRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on HomeDoorRemoteException {
      rethrow;
    }
  }

  bool _isSuccessCode(int code) => code == 0 || code == 200;
}

class HomeDoorRemoteException implements Exception {
  const HomeDoorRemoteException._(this.kind, {this.statusCode});

  HomeDoorRemoteException.fromNetwork(NetworkException exception)
    : this._(HomeDoorRemoteErrorKind.network, statusCode: exception.statusCode);
  const HomeDoorRemoteException.invalidResponse()
    : this._(HomeDoorRemoteErrorKind.invalidResponse);

  final HomeDoorRemoteErrorKind kind;
  final int? statusCode;
}

enum HomeDoorRemoteErrorKind { network, invalidResponse }
