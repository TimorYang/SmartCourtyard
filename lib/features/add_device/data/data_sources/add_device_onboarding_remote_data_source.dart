import 'package:dio/dio.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_business_failure.dart';
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
    int? sceneId,
    required int doorType,
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
      if (!response.isBusinessSuccess) {
        throw AddDeviceOnboardingRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null || !data.isValid) {
        throw const AddDeviceOnboardingRemoteException.invalidResponse();
      }
      if (!data.canBind) {
        if (data.bound) {
          throw AddDeviceOnboardingRemoteException.alreadyBound(
            ownedByCurrentUser: data.ownedByCurrentUser,
          );
        }
        throw const AddDeviceOnboardingRemoteException.invalidResponse();
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
      if (!response.isBusinessSuccess) {
        throw AddDeviceOnboardingRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null || !data.isValid) {
        throw const AddDeviceOnboardingRemoteException.invalidResponse();
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
    int? sceneId,
    required int doorType,
    required String requestId,
  }) async {
    try {
      final response = await api.addForceDoor(
        AddForceDoorRequestDto(
          sn: sn,
          doorId: doorId,
          sceneId: sceneId,
          doorType: doorType,
        ),
        Options(extra: _bindingRequestExtras(requestId)),
      );
      final data = response.data;
      if (!response.isBusinessSuccess) {
        throw AddDeviceOnboardingRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const AddDeviceOnboardingRemoteException.invalidResponse();
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
    this.network,
    this.businessFailure,
  });

  AddDeviceOnboardingRemoteException.fromNetwork(NetworkException exception)
    : this._(AddDeviceOnboardingRemoteErrorKind.network, network: exception);

  const AddDeviceOnboardingRemoteException.businessFailure(
    ApiBusinessFailure failure,
  ) : this._(
        AddDeviceOnboardingRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );

  const AddDeviceOnboardingRemoteException.invalidResponse()
    : this._(AddDeviceOnboardingRemoteErrorKind.invalidResponse);

  const AddDeviceOnboardingRemoteException.alreadyBound({
    required bool ownedByCurrentUser,
  }) : this._(
         ownedByCurrentUser
             ? AddDeviceOnboardingRemoteErrorKind.alreadyBoundToCurrentUser
             : AddDeviceOnboardingRemoteErrorKind.alreadyBoundToAnotherUser,
       );

  final AddDeviceOnboardingRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  int? get statusCode => network?.statusCode;
}

enum AddDeviceOnboardingRemoteErrorKind {
  network,
  businessFailure,
  invalidResponse,
  alreadyBoundToCurrentUser,
  alreadyBoundToAnotherUser,
}
