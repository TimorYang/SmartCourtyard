import 'package:dio/dio.dart';

import '../../../../core/network/api_business_failure.dart';
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

  Future<void> deleteScene({required int sceneId, required String requestId});

  Future<void> renameScene({
    required int sceneId,
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
      if (!response.isBusinessSuccess) {
        throw HomeSceneRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
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
      if (!response.isBusinessSuccess) {
        throw HomeSceneRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
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
  Future<void> deleteScene({
    required int sceneId,
    required String requestId,
  }) async {
    try {
      final response = await api.deleteScene(
        sceneId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!response.isBusinessSuccess) {
        throw HomeSceneRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
    } on DioException catch (error) {
      throw HomeSceneRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on HomeSceneRemoteException {
      rethrow;
    }
  }

  @override
  Future<void> renameScene({
    required int sceneId,
    required String name,
    required String requestId,
  }) async {
    try {
      final response = await api.renameScene(
        sceneId,
        CreateHomeSceneRequestDto(name: name),
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!response.isBusinessSuccess) {
        throw HomeSceneRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (response.data != true) {
        throw const HomeSceneRemoteException.invalidResponse();
      }
    } on DioException catch (error) {
      throw HomeSceneRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on HomeSceneRemoteException {
      rethrow;
    }
  }
}

class HomeSceneRemoteException implements Exception {
  const HomeSceneRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  HomeSceneRemoteException.fromNetwork(NetworkException exception)
    : this._(HomeSceneRemoteErrorKind.network, network: exception);
  const HomeSceneRemoteException.businessFailure(ApiBusinessFailure failure)
    : this._(
        HomeSceneRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );
  const HomeSceneRemoteException.invalidResponse()
    : this._(HomeSceneRemoteErrorKind.invalidResponse);

  final HomeSceneRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  int? get statusCode => network?.statusCode;
}

enum HomeSceneRemoteErrorKind { network, businessFailure, invalidResponse }
