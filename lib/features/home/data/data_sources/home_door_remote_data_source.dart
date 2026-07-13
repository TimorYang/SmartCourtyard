import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/home_door_response_dto.dart';
import 'home_api.dart';

abstract interface class HomeDoorRemoteDataSource {
  Future<List<HomeDoorResponseDto>> fetchDoors({
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
