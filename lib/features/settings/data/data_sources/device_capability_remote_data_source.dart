import 'package:dio/dio.dart';

import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/device_capability_response_dto.dart';
import 'device_capability_api.dart';

abstract interface class DeviceCapabilityRemoteDataSource {
  Future<List<DeviceCapabilityResponseDto>> fetchCapabilities({
    required String deviceId,
    required String requestId,
  });
}

class DeviceCapabilityRemoteDataSourceImpl
    implements DeviceCapabilityRemoteDataSource {
  const DeviceCapabilityRemoteDataSourceImpl({required this.api});

  final DeviceCapabilityApi api;

  @override
  Future<List<DeviceCapabilityResponseDto>> fetchCapabilities({
    required String deviceId,
    required String requestId,
  }) async {
    try {
      final response = await api.fetchCapabilities(
        deviceId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (!response.isBusinessSuccess) {
        throw DeviceCapabilityRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const DeviceCapabilityRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw DeviceCapabilityRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on DeviceCapabilityRemoteException {
      rethrow;
    }
  }
}

class DeviceCapabilityRemoteException implements Exception {
  const DeviceCapabilityRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  DeviceCapabilityRemoteException.fromNetwork(NetworkException exception)
    : this._(DeviceCapabilityRemoteErrorKind.network, network: exception);

  const DeviceCapabilityRemoteException.businessFailure(
    ApiBusinessFailure failure,
  ) : this._(
        DeviceCapabilityRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );

  const DeviceCapabilityRemoteException.invalidResponse()
    : this._(DeviceCapabilityRemoteErrorKind.invalidResponse);

  final DeviceCapabilityRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  int? get statusCode => network?.statusCode;
}

enum DeviceCapabilityRemoteErrorKind {
  network,
  businessFailure,
  invalidResponse,
}
