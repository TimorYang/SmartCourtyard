import 'package:dio/dio.dart';

import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/api_envelope_dto.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/remote_door_command_request_dto.dart';
import '../dto/remote_door_command_response_dto.dart';
import 'remote_door_command_api.dart';

abstract interface class RemoteDoorCommandRemoteDataSource {
  Future<RemoteDoorCommandResponseDto> submitCommand({
    required int doorId,
    required RemoteDoorCommandRequestDto body,
    required String requestId,
  });
}

class RemoteDoorCommandRemoteDataSourceImpl
    implements RemoteDoorCommandRemoteDataSource {
  const RemoteDoorCommandRemoteDataSourceImpl({required this.api});

  final RemoteDoorCommandApi api;

  @override
  Future<RemoteDoorCommandResponseDto> submitCommand({
    required int doorId,
    required RemoteDoorCommandRequestDto body,
    required String requestId,
  }) async {
    try {
      final response = await api.submitCommand(
        doorId,
        body,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      return _validated(response);
    } on DioException catch (error) {
      throw RemoteDoorCommandRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on RemoteDoorCommandRemoteException {
      rethrow;
    }
  }

  RemoteDoorCommandResponseDto _validated(
    ApiEnvelopeDto<RemoteDoorCommandResponseDto> response,
  ) {
    if ((response.code != 0 && response.code != 200) || !response.success) {
      throw RemoteDoorCommandRemoteException.businessFailure(
        ApiBusinessFailure.fromEnvelope(response),
      );
    }
    final data = response.data;
    if (data == null ||
        data.commandId.trim().isEmpty ||
        data.doorId.trim().isEmpty ||
        data.action.trim().isEmpty ||
        data.status.trim().isEmpty) {
      throw const RemoteDoorCommandRemoteException.invalidResponse();
    }
    return data;
  }
}

class RemoteDoorCommandRemoteException implements Exception {
  const RemoteDoorCommandRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  RemoteDoorCommandRemoteException.fromNetwork(NetworkException exception)
    : this._(RemoteDoorCommandRemoteErrorKind.network, network: exception);

  const RemoteDoorCommandRemoteException.businessFailure(
    ApiBusinessFailure failure,
  ) : this._(
        RemoteDoorCommandRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );

  const RemoteDoorCommandRemoteException.invalidResponse()
    : this._(RemoteDoorCommandRemoteErrorKind.invalidResponse);

  final RemoteDoorCommandRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  int? get statusCode => network?.statusCode;
}

enum RemoteDoorCommandRemoteErrorKind {
  network,
  businessFailure,
  invalidResponse,
}
