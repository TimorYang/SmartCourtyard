import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/shared_door_response_dto.dart';
import '../dto/shared_door_members_response_dto.dart';
import 'shared_devices_api.dart';

abstract interface class SharedDevicesRemoteDataSource {
  Future<List<SharedDoorResponseDto>> fetchSharedDoors({
    required String requestId,
  });
  Future<SharedDoorMembersResponseDto> fetchDoorMembers({
    required int doorId,
    required String requestId,
  });
  Future<void> deleteDoorMember({
    required int shareId,
    required String requestId,
  });
}

class SharedDevicesRemoteDataSourceImpl
    implements SharedDevicesRemoteDataSource {
  const SharedDevicesRemoteDataSourceImpl({required this.api});

  final SharedDevicesApi api;

  @override
  Future<List<SharedDoorResponseDto>> fetchSharedDoors({
    required String requestId,
  }) async {
    try {
      final response = await api.fetchSharedDoors(
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (response.code != 200 || !response.success) {
        throw SharedDevicesRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const SharedDevicesRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw SharedDevicesRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on SharedDevicesRemoteException {
      rethrow;
    } on FormatException {
      throw const SharedDevicesRemoteException.invalidResponse();
    }
  }

  @override
  Future<void> deleteDoorMember({
    required int shareId,
    required String requestId,
  }) async {
    try {
      final response = await api.deleteDoorMember(
        shareId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (response.code != 200 || !response.success) {
        throw SharedDevicesRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
    } on DioException catch (error) {
      throw SharedDevicesRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on SharedDevicesRemoteException {
      rethrow;
    }
  }

  @override
  Future<SharedDoorMembersResponseDto> fetchDoorMembers({
    required int doorId,
    required String requestId,
  }) async {
    try {
      final response = await api.fetchDoorMembers(
        doorId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (response.code != 200 || !response.success) {
        throw SharedDevicesRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (response.data == null) {
        throw const SharedDevicesRemoteException.invalidResponse();
      }
      return response.data!;
    } on DioException catch (error) {
      throw SharedDevicesRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on SharedDevicesRemoteException {
      rethrow;
    }
  }
}

class SharedDevicesRemoteException implements Exception {
  const SharedDevicesRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  SharedDevicesRemoteException.fromNetwork(NetworkException exception)
    : this._(SharedDevicesRemoteErrorKind.network, network: exception);

  SharedDevicesRemoteException.businessFailure(ApiBusinessFailure failure)
    : this._(
        SharedDevicesRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );

  const SharedDevicesRemoteException.invalidResponse()
    : this._(SharedDevicesRemoteErrorKind.invalidResponse);

  final SharedDevicesRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  int? get statusCode => network?.statusCode;
}

enum SharedDevicesRemoteErrorKind { network, businessFailure, invalidResponse }
