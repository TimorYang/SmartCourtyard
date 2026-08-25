import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/door_share_dto.dart';
import 'home_api.dart';

abstract interface class DoorShareRemoteDataSource {
  Future<List<ShareCapabilityResponseDto>> fetchCapabilities({
    required int doorId,
    required String requestId,
  });
  Future<void> createShare({
    required int doorId,
    required CreateDoorShareRequestDto request,
    required String requestId,
  });
  Future<void> updateShare({
    required int shareId,
    required UpdateDoorShareRequestDto request,
    required String requestId,
  });
}

class DoorShareRemoteDataSourceImpl implements DoorShareRemoteDataSource {
  const DoorShareRemoteDataSourceImpl({required this.api});
  final HomeApi api;

  @override
  Future<List<ShareCapabilityResponseDto>> fetchCapabilities({
    required int doorId,
    required String requestId,
  }) async {
    try {
      final response = await api.fetchDoorShareCapabilities(
        doorId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if ((response.code != 0 && response.code != 200) || !response.success) {
        throw const DoorShareRemoteException.invalidResponse();
      }
      return response.data ?? const [];
    } on DioException catch (error) {
      throw DoorShareRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on DoorShareRemoteException {
      rethrow;
    }
  }

  @override
  Future<void> createShare({
    required int doorId,
    required CreateDoorShareRequestDto request,
    required String requestId,
  }) async {
    try {
      final response = await api.createDoorShare(
        doorId,
        request,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if ((response.code != 0 && response.code != 200) || !response.success) {
        throw const DoorShareRemoteException.invalidResponse();
      }
    } on DioException catch (error) {
      throw DoorShareRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on DoorShareRemoteException {
      rethrow;
    }
  }

  @override
  Future<void> updateShare({
    required int shareId,
    required UpdateDoorShareRequestDto request,
    required String requestId,
  }) async {
    try {
      final response = await api.updateDoorShare(
        shareId,
        request,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if ((response.code != 0 && response.code != 200) || !response.success) {
        throw const DoorShareRemoteException.invalidResponse();
      }
    } on DioException catch (error) {
      throw DoorShareRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on DoorShareRemoteException {
      rethrow;
    }
  }
}

class DoorShareRemoteException implements Exception {
  const DoorShareRemoteException._(this.kind, {this.statusCode});
  DoorShareRemoteException.fromNetwork(NetworkException exception)
    : this._(
        DoorShareRemoteErrorKind.network,
        statusCode: exception.statusCode,
      );
  const DoorShareRemoteException.invalidResponse()
    : this._(DoorShareRemoteErrorKind.invalidResponse);
  final DoorShareRemoteErrorKind kind;
  final int? statusCode;
}

enum DoorShareRemoteErrorKind { network, invalidResponse }
