import 'package:dio/dio.dart';

import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/door_detail_response_dto.dart';
import '../dto/door_device_response_dto.dart';
import '../dto/about_device_info_response_dto.dart';
import 'door_detail_api.dart';

abstract interface class DoorDetailRemoteDataSource {
  Future<DoorDetailResponseDto> fetchDoorDetail({
    required int doorId,
    required String requestId,
  });

  Future<List<DoorDeviceResponseDto>> fetchDoorDevices({
    required int doorId,
    required String requestId,
  });

  Future<AboutDeviceInfoResponseDto> fetchAboutDeviceInfo({
    required int doorId,
    required int deviceId,
    required String requestId,
  });

  Future<void> unbindDoorDevice({
    required int doorId,
    required int deviceId,
    required String requestId,
  });
}

class DoorDetailRemoteDataSourceImpl implements DoorDetailRemoteDataSource {
  const DoorDetailRemoteDataSourceImpl({required this.api});

  final DoorDetailApi api;

  @override
  Future<DoorDetailResponseDto> fetchDoorDetail({
    required int doorId,
    required String requestId,
  }) async {
    try {
      final response = await api.fetchDoorDetail(
        doorId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (!response.isBusinessSuccess) {
        throw DoorDetailRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const DoorDetailRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw DoorDetailRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on DoorDetailRemoteException {
      rethrow;
    }
  }

  @override
  Future<List<DoorDeviceResponseDto>> fetchDoorDevices({
    required int doorId,
    required String requestId,
  }) async {
    try {
      final response = await api.fetchDoorDevices(
        doorId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (!response.isBusinessSuccess) {
        throw DoorDetailRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const DoorDetailRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw DoorDetailRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on DoorDetailRemoteException {
      rethrow;
    }
  }

  @override
  Future<AboutDeviceInfoResponseDto> fetchAboutDeviceInfo({
    required int doorId,
    required int deviceId,
    required String requestId,
  }) async {
    try {
      final response = await api.fetchAboutDeviceInfo(
        doorId,
        deviceId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (!response.isBusinessSuccess) {
        throw DoorDetailRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const DoorDetailRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw DoorDetailRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on DoorDetailRemoteException {
      rethrow;
    }
  }

  @override
  Future<void> unbindDoorDevice({
    required int doorId,
    required int deviceId,
    required String requestId,
  }) async {
    try {
      final response = await api.unbindDoorDevice(
        doorId,
        deviceId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!response.isBusinessSuccess) {
        throw DoorDetailRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (response.data != true) {
        throw const DoorDetailRemoteException.invalidResponse();
      }
    } on DioException catch (error) {
      throw DoorDetailRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on DoorDetailRemoteException {
      rethrow;
    }
  }
}

class DoorDetailRemoteException implements Exception {
  const DoorDetailRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  DoorDetailRemoteException.fromNetwork(NetworkException exception)
    : this._(DoorDetailRemoteErrorKind.network, network: exception);
  const DoorDetailRemoteException.businessFailure(ApiBusinessFailure failure)
    : this._(
        DoorDetailRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );
  const DoorDetailRemoteException.invalidResponse()
    : this._(DoorDetailRemoteErrorKind.invalidResponse);

  final DoorDetailRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  int? get statusCode => network?.statusCode;
}

enum DoorDetailRemoteErrorKind { network, businessFailure, invalidResponse }
