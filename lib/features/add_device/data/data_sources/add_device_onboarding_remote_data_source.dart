import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/add_force_door_request_dto.dart';
import '../dto/force_door_response_dto.dart';
import '../dto/onboarding_device_key_response_dto.dart';
import 'add_device_onboarding_api.dart';

abstract interface class AddDeviceOnboardingRemoteDataSource {
  Future<OnboardingDeviceKeyResponseDto> fetchDeviceKey({
    required String sn,
    required String requestId,
  });

  Future<ForceDoorResponseDto> addForceDoor({
    required String sn,
    required String requestId,
  });
}

class AddDeviceOnboardingRemoteDataSourceImpl
    implements AddDeviceOnboardingRemoteDataSource {
  const AddDeviceOnboardingRemoteDataSourceImpl({required this.api});

  final AddDeviceOnboardingApi api;

  @override
  Future<OnboardingDeviceKeyResponseDto> fetchDeviceKey({
    required String sn,
    required String requestId,
  }) async {
    try {
      final response = await api.fetchDeviceKey(
        sn,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (!_isSuccessCode(response.code) ||
          !response.success ||
          data == null ||
          !data.isValid) {
        throw AddDeviceOnboardingRemoteException.invalidResponse(
          serverCode: response.code,
          serverMessageKey: response.messageKey,
        );
      }
      return data;
    } on DioException catch (error) {
      throw AddDeviceOnboardingRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on AddDeviceOnboardingRemoteException {
      rethrow;
    }
  }

  @override
  Future<ForceDoorResponseDto> addForceDoor({
    required String sn,
    required String requestId,
  }) async {
    try {
      final response = await api.addForceDoor(
        AddForceDoorRequestDto(sn: sn),
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (!_isSuccessCode(response.code) ||
          !response.success ||
          data == null ||
          !data.isValid) {
        throw AddDeviceOnboardingRemoteException.invalidResponse(
          serverCode: response.code,
          serverMessageKey: response.messageKey,
        );
      }
      return data;
    } on DioException catch (error) {
      throw AddDeviceOnboardingRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on AddDeviceOnboardingRemoteException {
      rethrow;
    }
  }

  bool _isSuccessCode(int code) => code == 0 || code == 200;
}

class AddDeviceOnboardingRemoteException implements Exception {
  const AddDeviceOnboardingRemoteException._(
    this.kind, {
    this.statusCode,
    this.serverCode,
    this.serverMessageKey,
  });

  AddDeviceOnboardingRemoteException.fromNetwork(NetworkException exception)
    : this._(
        AddDeviceOnboardingRemoteErrorKind.network,
        statusCode: exception.statusCode,
      );

  const AddDeviceOnboardingRemoteException.invalidResponse({
    int? serverCode,
    String? serverMessageKey,
  }) : this._(
         AddDeviceOnboardingRemoteErrorKind.invalidResponse,
         serverCode: serverCode,
         serverMessageKey: serverMessageKey,
       );

  final AddDeviceOnboardingRemoteErrorKind kind;
  final int? statusCode;
  final int? serverCode;
  final String? serverMessageKey;
}

enum AddDeviceOnboardingRemoteErrorKind { network, invalidResponse }
