import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/receiving_door_response_dto.dart';
import 'receiving_devices_api.dart';

abstract interface class ReceivingDevicesRemoteDataSource {
  Future<List<ReceivingDoorResponseDto>> fetchReceivingDoors({
    required String requestId,
  });
}

class ReceivingDevicesRemoteDataSourceImpl
    implements ReceivingDevicesRemoteDataSource {
  const ReceivingDevicesRemoteDataSourceImpl({required this.api});

  final ReceivingDevicesApi api;

  @override
  Future<List<ReceivingDoorResponseDto>> fetchReceivingDoors({
    required String requestId,
  }) async {
    try {
      final response = await api.fetchReceivingDoors(
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if ((response.code != 0 && response.code != 200) ||
          !response.success ||
          data == null) {
        throw const ReceivingDevicesRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw ReceivingDevicesRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on ReceivingDevicesRemoteException {
      rethrow;
    } on FormatException {
      throw const ReceivingDevicesRemoteException.invalidResponse();
    }
  }
}

class ReceivingDevicesRemoteException implements Exception {
  const ReceivingDevicesRemoteException._(this.kind, {this.statusCode});

  ReceivingDevicesRemoteException.fromNetwork(NetworkException exception)
    : this._(
        ReceivingDevicesRemoteErrorKind.network,
        statusCode: exception.statusCode,
      );

  const ReceivingDevicesRemoteException.invalidResponse()
    : this._(ReceivingDevicesRemoteErrorKind.invalidResponse);

  final ReceivingDevicesRemoteErrorKind kind;
  final int? statusCode;
}

enum ReceivingDevicesRemoteErrorKind { network, invalidResponse }
