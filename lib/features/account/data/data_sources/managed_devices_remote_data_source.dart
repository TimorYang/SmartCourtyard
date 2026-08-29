import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/managed_login_device_dto.dart';
import 'managed_devices_api.dart';

abstract interface class ManagedDevicesRemoteDataSource {
  Future<List<ManagedLoginDeviceDto>> fetchLoginDevices({
    required String requestId,
  });

  Future<void> removeLoginDevice({
    required String sessionId,
    required String requestId,
  });
}

class ManagedDevicesRemoteDataSourceImpl
    implements ManagedDevicesRemoteDataSource {
  const ManagedDevicesRemoteDataSourceImpl({required this.api});

  final ManagedDevicesApi api;

  @override
  Future<List<ManagedLoginDeviceDto>> fetchLoginDevices({
    required String requestId,
  }) async {
    try {
      final response = await api.fetchLoginDevices(
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!_isSuccessful(response.code, response.success)) {
        throw ManagedDevicesRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (response.data == null) {
        throw const ManagedDevicesRemoteException.invalidResponse();
      }
      return response.data!;
    } on DioException catch (error) {
      throw ManagedDevicesRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on ManagedDevicesRemoteException {
      rethrow;
    }
  }

  @override
  Future<void> removeLoginDevice({
    required String sessionId,
    required String requestId,
  }) async {
    try {
      final response = await api.removeLoginDevice(
        sessionId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!_isSuccessful(response.code, response.success)) {
        throw ManagedDevicesRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
    } on DioException catch (error) {
      throw ManagedDevicesRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on ManagedDevicesRemoteException {
      rethrow;
    }
  }

  bool _isSuccessful(int code, bool success) => code == 200 && success;
}

class ManagedDevicesRemoteException implements Exception {
  const ManagedDevicesRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  ManagedDevicesRemoteException.fromNetwork(NetworkException exception)
    : this._(ManagedDevicesRemoteErrorKind.network, network: exception);

  ManagedDevicesRemoteException.businessFailure(ApiBusinessFailure failure)
    : this._(
        ManagedDevicesRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );

  const ManagedDevicesRemoteException.invalidResponse()
    : this._(ManagedDevicesRemoteErrorKind.invalidResponse);

  final ManagedDevicesRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  int? get statusCode => network?.statusCode;
}

enum ManagedDevicesRemoteErrorKind { network, businessFailure, invalidResponse }
