import 'package:dio/dio.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/add_force_door_request_dto.dart';
import '../dto/force_door_response_dto.dart';
import '../dto/onboarding_device_key_response_dto.dart';
import 'add_device_onboarding_api.dart';

abstract interface class AddDeviceOnboardingRemoteDataSource {
  Future<void> validateBindingStatus({
    required String sn,
    required String requestId,
  });

  Future<OnboardingDeviceKeyResponseDto> fetchDeviceKey({
    required String sn,
    required String requestId,
  });

  Future<ForceDoorResponseDto> addForceDoor({
    required String sn,
    String? doorId,
    required String requestId,
  });
}

class AddDeviceOnboardingRemoteDataSourceImpl
    implements AddDeviceOnboardingRemoteDataSource {
  const AddDeviceOnboardingRemoteDataSourceImpl({required this.api});

  final AddDeviceOnboardingApi api;

  @override
  Future<void> validateBindingStatus({
    required String sn,
    required String requestId,
  }) async {
    try {
      final response = await api.validateBindingStatus(
        sn,
        Options(extra: _bindingRequestExtras(requestId)),
      );
      final data = response.data;
      if (!_isSuccessCode(response.code) ||
          !response.success ||
          data == null ||
          !data.isValid ||
          !data.canBind) {
        throw AddDeviceOnboardingRemoteException.invalidResponse(
          serverCode: response.code,
          serverMessage: response.success ? null : response.msg,
          serverMessageKey: response.messageKey,
        );
      }
    } on DioException catch (error) {
      throw AddDeviceOnboardingRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on AddDeviceOnboardingRemoteException {
      rethrow;
    }
  }

  @override
  Future<OnboardingDeviceKeyResponseDto> fetchDeviceKey({
    required String sn,
    required String requestId,
  }) async {
    try {
      final response = await api.fetchDeviceKey(
        sn,
        Options(extra: _bindingRequestExtras(requestId)),
      );
      final data = response.data;
      if (!_isSuccessCode(response.code) ||
          !response.success ||
          data == null ||
          !data.isValid) {
        throw AddDeviceOnboardingRemoteException.invalidResponse(
          serverCode: response.code,
          serverMessage: response.msg,
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
    String? doorId,
    required String requestId,
  }) async {
    try {
      final response = await api.addForceDoor(
        AddForceDoorRequestDto(sn: sn, doorId: doorId),
        Options(extra: _bindingRequestExtras(requestId)),
      );
      final data = response.data;
      if (response.code != 200 || data == null) {
        throw AddDeviceOnboardingRemoteException.invalidResponse(
          serverCode: response.code,
          serverMessage: response.msg,
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

  Map<String, Object?> _bindingRequestExtras(String requestId) {
    return {
      NetworkRequestExtras.requestId: requestId,
      NetworkRequestExtras.flowId: requestId.split(':').first,
      NetworkRequestExtras.logTag: AppLogTag.binding,
    };
  }
}

class AddDeviceOnboardingRemoteException implements Exception {
  const AddDeviceOnboardingRemoteException._(
    this.kind, {
    this.statusCode,
    this.serverCode,
    this.serverMessage,
    this.serverMessageKey,
  });

  AddDeviceOnboardingRemoteException.fromNetwork(NetworkException exception)
    : this._(
        AddDeviceOnboardingRemoteErrorKind.network,
        statusCode: exception.statusCode,
      );

  const AddDeviceOnboardingRemoteException.invalidResponse({
    int? serverCode,
    String? serverMessage,
    String? serverMessageKey,
  }) : this._(
         AddDeviceOnboardingRemoteErrorKind.invalidResponse,
         serverCode: serverCode,
         serverMessage: serverMessage,
         serverMessageKey: serverMessageKey,
       );

  final AddDeviceOnboardingRemoteErrorKind kind;
  final int? statusCode;
  final int? serverCode;
  final String? serverMessage;
  final String? serverMessageKey;
}

enum AddDeviceOnboardingRemoteErrorKind { network, invalidResponse }
