import 'package:dio/dio.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../../domain/entities/push_registration.dart';
import '../dto/engage_lab_registration_request_dto.dart';
import 'engage_lab_push_api.dart';

abstract interface class EngageLabPushRemoteDataSource {
  Future<void> bind({
    required PushRegistration registration,
    required String requestId,
  });

  Future<void> unbind({required String requestId});
}

class EngageLabPushRemoteDataSourceImpl
    implements EngageLabPushRemoteDataSource {
  const EngageLabPushRemoteDataSourceImpl({required this.api});

  final EngageLabPushApi api;

  @override
  Future<void> bind({
    required PushRegistration registration,
    required String requestId,
  }) async {
    try {
      final response = await api.bindRegistrationId(
        EngageLabRegistrationRequestDto(
          registrationId: registration.registrationId,
          deviceId: registration.deviceId,
          platform: registration.platform.wireValue,
        ),
        _options(requestId),
      );
      _validateResponse(response);
    } on DioException catch (error) {
      throw EngageLabPushRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on EngageLabPushRemoteException {
      rethrow;
    } on Object {
      throw const EngageLabPushRemoteException.invalidResponse();
    }
  }

  @override
  Future<void> unbind({required String requestId}) async {
    try {
      final response = await api.unbindRegistrationId(
        Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            Headers.contentTypeHeader: Headers.formUrlEncodedContentType,
          },
          extra: {
            NetworkRequestExtras.requestId: requestId,
            NetworkRequestExtras.logTag: AppLogTag.push,
          },
        ),
      );
      _validateResponse(response);
    } on DioException catch (error) {
      throw EngageLabPushRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on EngageLabPushRemoteException {
      rethrow;
    } on Object {
      throw const EngageLabPushRemoteException.invalidResponse();
    }
  }

  Options _options(String requestId) => Options(
    extra: {
      NetworkRequestExtras.requestId: requestId,
      NetworkRequestExtras.logTag: AppLogTag.push,
    },
  );

  void _validateResponse(ApiEnvelopeDto<dynamic> response) {
    if (!response.isBusinessSuccess) {
      throw EngageLabPushRemoteException.businessFailure(
        ApiBusinessFailure.fromEnvelope(response),
      );
    }
  }
}

class EngageLabPushRemoteException implements Exception {
  const EngageLabPushRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  EngageLabPushRemoteException.fromNetwork(NetworkException exception)
    : this._(EngageLabPushRemoteErrorKind.network, network: exception);

  const EngageLabPushRemoteException.businessFailure(ApiBusinessFailure failure)
    : this._(
        EngageLabPushRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );

  const EngageLabPushRemoteException.invalidResponse()
    : this._(EngageLabPushRemoteErrorKind.invalidResponse);

  final EngageLabPushRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;

  int? get statusCode => network?.statusCode;
}

enum EngageLabPushRemoteErrorKind { network, businessFailure, invalidResponse }
