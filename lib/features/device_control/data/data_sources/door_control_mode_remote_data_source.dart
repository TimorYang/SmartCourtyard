import 'package:dio/dio.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/update_door_control_mode_request_dto.dart';
import 'door_control_mode_api.dart';

abstract interface class DoorControlModeRemoteDataSource {
  Future<void> updateControlMode({
    required String sn,
    required String controlMode,
    required String requestId,
  });
}

class DoorControlModeRemoteDataSourceImpl
    implements DoorControlModeRemoteDataSource {
  const DoorControlModeRemoteDataSourceImpl({required this.api});

  final DoorControlModeApi api;

  @override
  Future<void> updateControlMode({
    required String sn,
    required String controlMode,
    required String requestId,
  }) async {
    try {
      final response = await api.updateControlMode(
        UpdateDoorControlModeRequestDto(sn: sn, controlMode: controlMode),
        Options(
          extra: {
            NetworkRequestExtras.requestId: requestId,
            NetworkRequestExtras.flowId: requestId.split(':').first,
            NetworkRequestExtras.logTag: AppLogTag.general,
          },
        ),
      );
      if (!response.isBusinessSuccess) {
        throw DoorControlModeRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      // The endpoint returns an empty object in data. There is no response
      // field to map or validate after the business envelope succeeds.
    } on DioException catch (error) {
      throw DoorControlModeRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on DoorControlModeRemoteException {
      rethrow;
    }
  }
}

class DoorControlModeRemoteException implements Exception {
  const DoorControlModeRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  DoorControlModeRemoteException.fromNetwork(NetworkException exception)
    : this._(DoorControlModeRemoteErrorKind.network, network: exception);

  const DoorControlModeRemoteException.businessFailure(
    ApiBusinessFailure failure,
  ) : this._(
        DoorControlModeRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );

  final DoorControlModeRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
}

enum DoorControlModeRemoteErrorKind { network, businessFailure }
