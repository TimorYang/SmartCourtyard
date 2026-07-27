import 'package:dio/dio.dart';

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
      if ((response.code != 0 && response.code != 200) ||
          !response.success ||
          status == null ||
          !const {'0', '1', '2'}.contains(status)) {
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
  const SecurityCenterConnectionStatusRemoteException._(this.kind);

  SecurityCenterConnectionStatusRemoteException.fromNetwork(
    NetworkException exception,
  ) : this._(SecurityCenterConnectionStatusRemoteErrorKind.network);

  const SecurityCenterConnectionStatusRemoteException.invalidResponse()
    : this._(SecurityCenterConnectionStatusRemoteErrorKind.invalidResponse);

  final SecurityCenterConnectionStatusRemoteErrorKind kind;
}

enum SecurityCenterConnectionStatusRemoteErrorKind { network, invalidResponse }
