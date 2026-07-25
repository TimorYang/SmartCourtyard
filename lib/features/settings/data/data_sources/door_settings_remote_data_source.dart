import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/door_setting_response_dto.dart';
import 'door_settings_api.dart';

abstract interface class DoorSettingsRemoteDataSource {
  Future<List<DoorSettingResponseDto>> fetchSettings({
    required int doorId,
    required String requestId,
  });
}

class DoorSettingsRemoteDataSourceImpl implements DoorSettingsRemoteDataSource {
  const DoorSettingsRemoteDataSourceImpl({required this.api});

  final DoorSettingsApi api;

  @override
  Future<List<DoorSettingResponseDto>> fetchSettings({
    required int doorId,
    required String requestId,
  }) async {
    try {
      final response = await api.fetchSettings(
        doorId,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if ((response.code != 0 && response.code != 200) ||
          !response.success ||
          data == null) {
        throw const DoorSettingsRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw DoorSettingsRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on DoorSettingsRemoteException {
      rethrow;
    }
  }
}

class DoorSettingsRemoteException implements Exception {
  const DoorSettingsRemoteException._(this.kind, {this.statusCode});

  DoorSettingsRemoteException.fromNetwork(NetworkException exception)
    : this._(
        DoorSettingsRemoteErrorKind.network,
        statusCode: exception.statusCode,
      );

  const DoorSettingsRemoteException.invalidResponse()
    : this._(DoorSettingsRemoteErrorKind.invalidResponse);

  final DoorSettingsRemoteErrorKind kind;
  final int? statusCode;
}

enum DoorSettingsRemoteErrorKind { network, invalidResponse }
