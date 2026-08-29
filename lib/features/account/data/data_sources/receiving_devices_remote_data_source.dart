import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/api_business_failure.dart';
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
      if (response.code != 200 || !response.success) {
        throw ReceivingDevicesRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
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
  const ReceivingDevicesRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  ReceivingDevicesRemoteException.fromNetwork(NetworkException exception)
    : this._(ReceivingDevicesRemoteErrorKind.network, network: exception);

  ReceivingDevicesRemoteException.businessFailure(ApiBusinessFailure failure)
    : this._(
        ReceivingDevicesRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );

  const ReceivingDevicesRemoteException.invalidResponse()
    : this._(ReceivingDevicesRemoteErrorKind.invalidResponse);

  final ReceivingDevicesRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  int? get statusCode => network?.statusCode;
}

enum ReceivingDevicesRemoteErrorKind {
  network,
  businessFailure,
  invalidResponse,
}
