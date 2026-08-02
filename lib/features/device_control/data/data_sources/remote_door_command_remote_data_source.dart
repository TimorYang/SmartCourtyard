import 'package:dio/dio.dart';

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

  Future<RemoteDoorCommandResponseDto> fetchCommand({
    required int doorId,
    required String commandId,
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
      return _validated(response.code, response.success, response.data);
    } on DioException catch (error) {
      throw RemoteDoorCommandRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on RemoteDoorCommandRemoteException {
      rethrow;
    }
  }

  @override
  Future<RemoteDoorCommandResponseDto> fetchCommand({
    required int doorId,
    required String commandId,
    required String requestId,
  }) async {
    try {
      final response = await api.fetchCommand(
        doorId,
        commandId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      return _validated(response.code, response.success, response.data);
    } on DioException catch (error) {
      throw RemoteDoorCommandRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on RemoteDoorCommandRemoteException {
      rethrow;
    }
  }

  RemoteDoorCommandResponseDto _validated(
    int code,
    bool success,
    RemoteDoorCommandResponseDto? data,
  ) {
    if ((code != 0 && code != 200) ||
        !success ||
        data == null ||
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
  const RemoteDoorCommandRemoteException._(this.kind, {this.statusCode});

  RemoteDoorCommandRemoteException.fromNetwork(NetworkException exception)
    : this._(
        RemoteDoorCommandRemoteErrorKind.network,
        statusCode: exception.statusCode,
      );

  const RemoteDoorCommandRemoteException.invalidResponse()
    : this._(RemoteDoorCommandRemoteErrorKind.invalidResponse);

  final RemoteDoorCommandRemoteErrorKind kind;
  final int? statusCode;
}

enum RemoteDoorCommandRemoteErrorKind { network, invalidResponse }
