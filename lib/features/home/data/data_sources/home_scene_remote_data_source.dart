import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/create_home_scene_request_dto.dart';
import '../dto/home_scene_response_dto.dart';
import 'home_api.dart';

abstract interface class HomeSceneRemoteDataSource {
  Future<List<HomeSceneResponseDto>> fetchScenes({required String requestId});

  Future<HomeSceneResponseDto> createScene({
    required String name,
    required String requestId,
  });
}

class HomeSceneRemoteDataSourceImpl implements HomeSceneRemoteDataSource {
  const HomeSceneRemoteDataSourceImpl({required this.api});

  final HomeApi api;

  @override
  Future<List<HomeSceneResponseDto>> fetchScenes({
    required String requestId,
  }) async {
    try {
      final response = await api.fetchScenes(
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (!_isSuccessCode(response.code) || !response.success || data == null) {
        throw const HomeSceneRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw HomeSceneRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on HomeSceneRemoteException {
      rethrow;
    }
  }

  @override
  Future<HomeSceneResponseDto> createScene({
    required String name,
    required String requestId,
  }) async {
    try {
      final response = await api.createScene(
        CreateHomeSceneRequestDto(name: name),
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (!_isSuccessCode(response.code) || !response.success || data == null) {
        throw const HomeSceneRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw HomeSceneRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on HomeSceneRemoteException {
      rethrow;
    }
  }

  bool _isSuccessCode(int code) => code == 0 || code == 200;
}

class HomeSceneRemoteException implements Exception {
  const HomeSceneRemoteException._(this.kind, {this.statusCode});

  HomeSceneRemoteException.fromNetwork(NetworkException exception)
    : this._(
        HomeSceneRemoteErrorKind.network,
        statusCode: exception.statusCode,
      );
  const HomeSceneRemoteException.invalidResponse()
    : this._(HomeSceneRemoteErrorKind.invalidResponse);

  final HomeSceneRemoteErrorKind kind;
  final int? statusCode;
}

enum HomeSceneRemoteErrorKind { network, invalidResponse }
