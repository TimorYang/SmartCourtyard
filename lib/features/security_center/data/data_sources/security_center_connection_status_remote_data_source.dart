import 'package:dio/dio.dart';

import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/security_center_connection_status_dto.dart';
import 'security_center_connection_status_api.dart';

abstract interface class SecurityCenterConnectionStatusRemoteDataSource {
  Future<SecurityCenterConnectionStatusDto> fetchConnectionStatus({
    required int doorId,
    required String requestId,
  });
}

class SecurityCenterConnectionStatusRemoteDataSourceImpl
    implements SecurityCenterConnectionStatusRemoteDataSource {
  const SecurityCenterConnectionStatusRemoteDataSourceImpl({required this.api});

  final SecurityCenterConnectionStatusApi api;

  @override
  Future<SecurityCenterConnectionStatusDto> fetchConnectionStatus({
    required int doorId,
    required String requestId,
  }) async {
    try {
      final response = await api.connectionStatus(
        doorId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final status = response.data?.wifiConnectionStatus?.trim();
      if (!response.isBusinessSuccess) {
        throw SecurityCenterConnectionStatusRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (status == null || !const {'0', '1', '2'}.contains(status)) {
        throw const SecurityCenterConnectionStatusRemoteException.invalidResponse();
      }
      return SecurityCenterConnectionStatusDto(
        wifiConnectionStatus: status,
        sensorStatus: response.data?.sensorStatus?.trim(),
        wiredSensors: response.data?.wiredSensors ?? const [],
        wirelessSensors: response.data?.wirelessSensors ?? const [],
      );
    } on DioException catch (error) {
      throw SecurityCenterConnectionStatusRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on SecurityCenterConnectionStatusRemoteException {
      rethrow;
    }
  }
}

class SecurityCenterConnectionStatusRemoteException implements Exception {
  const SecurityCenterConnectionStatusRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  SecurityCenterConnectionStatusRemoteException.fromNetwork(
    NetworkException exception,
  ) : this._(
        SecurityCenterConnectionStatusRemoteErrorKind.network,
        network: exception,
      );

  const SecurityCenterConnectionStatusRemoteException.businessFailure(
    ApiBusinessFailure failure,
  ) : this._(
        SecurityCenterConnectionStatusRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );

  const SecurityCenterConnectionStatusRemoteException.invalidResponse()
    : this._(SecurityCenterConnectionStatusRemoteErrorKind.invalidResponse);

  final SecurityCenterConnectionStatusRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
}

enum SecurityCenterConnectionStatusRemoteErrorKind {
  network,
  businessFailure,
  invalidResponse,
}
