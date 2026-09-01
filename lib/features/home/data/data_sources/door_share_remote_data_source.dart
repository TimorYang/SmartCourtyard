import 'package:dio/dio.dart';

import '../../../../core/network/api_business_failure.dart';
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
      if (!response.isBusinessSuccess) {
        throw DoorShareRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
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
      if (!response.isBusinessSuccess) {
        throw DoorShareRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
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
      if (!response.isBusinessSuccess) {
        throw DoorShareRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
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
  const DoorShareRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });
  DoorShareRemoteException.fromNetwork(NetworkException exception)
    : this._(DoorShareRemoteErrorKind.network, network: exception);
  const DoorShareRemoteException.businessFailure(ApiBusinessFailure failure)
    : this._(
        DoorShareRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );
  const DoorShareRemoteException.invalidResponse()
    : this._(DoorShareRemoteErrorKind.invalidResponse);
  final DoorShareRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  int? get statusCode => network?.statusCode;
}

enum DoorShareRemoteErrorKind { network, businessFailure, invalidResponse }
