import 'package:dio/dio.dart';

import '../../../../core/network/api_business_failure.dart';
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
      if (!response.isBusinessSuccess) {
        throw DoorSettingsRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
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
  const DoorSettingsRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  DoorSettingsRemoteException.fromNetwork(NetworkException exception)
    : this._(DoorSettingsRemoteErrorKind.network, network: exception);

  const DoorSettingsRemoteException.businessFailure(ApiBusinessFailure failure)
    : this._(
        DoorSettingsRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );

  const DoorSettingsRemoteException.invalidResponse()
    : this._(DoorSettingsRemoteErrorKind.invalidResponse);

  final DoorSettingsRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  int? get statusCode => network?.statusCode;
}

enum DoorSettingsRemoteErrorKind { network, businessFailure, invalidResponse }
