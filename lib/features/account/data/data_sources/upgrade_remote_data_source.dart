import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/upgrade_dto.dart';
import '../services/platform_app_release_context_provider.dart';
import 'upgrade_api.dart';

abstract interface class UpgradeRemoteDataSource {
  Future<AppReleaseCheckResponseDto> checkAppRelease({
    required String requestId,
  });

  Future<List<FirmwareUpgradeDoorDto>> fetchFirmwareUpgrades({
    required String requestId,
  });

  Future<List<FirmwareUpgradeSubmitResponseDto>> submitFirmwareUpgrades({
    required FirmwareUpgradeSubmitRequestDto request,
    required String requestId,
  });
}

class UpgradeRemoteDataSourceImpl implements UpgradeRemoteDataSource {
  const UpgradeRemoteDataSourceImpl({
    required this.api,
    required this.appReleaseContextProvider,
  });

  final UpgradeApi api;
  final PlatformAppReleaseContextProvider appReleaseContextProvider;

  @override
  Future<AppReleaseCheckResponseDto> checkAppRelease({
    required String requestId,
  }) async {
    try {
      final request = await appReleaseContextProvider.read();
      final response = await api.checkAppRelease(request, _options(requestId));
      final data = response.data;
      if (!response.isBusinessSuccess) {
        throw UpgradeRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const UpgradeRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw UpgradeRemoteException.fromNetwork(NetworkException.fromDio(error));
    } on UpgradeRemoteException {
      rethrow;
    } on Object {
      throw const UpgradeRemoteException.invalidResponse();
    }
  }

  @override
  Future<List<FirmwareUpgradeDoorDto>> fetchFirmwareUpgrades({
    required String requestId,
  }) async {
    try {
      final response = await api.fetchFirmwareUpgrades(_options(requestId));
      final data = response.data;
      if (!response.isBusinessSuccess) {
        throw UpgradeRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const UpgradeRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw UpgradeRemoteException.fromNetwork(NetworkException.fromDio(error));
    } on UpgradeRemoteException {
      rethrow;
    } on Object {
      throw const UpgradeRemoteException.invalidResponse();
    }
  }

  @override
  Future<List<FirmwareUpgradeSubmitResponseDto>> submitFirmwareUpgrades({
    required FirmwareUpgradeSubmitRequestDto request,
    required String requestId,
  }) async {
    try {
      final response = await api.submitFirmwareUpgrades(
        request,
        _options(requestId),
      );
      final data = response.data;
      if (!response.isBusinessSuccess) {
        throw UpgradeRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const UpgradeRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw UpgradeRemoteException.fromNetwork(NetworkException.fromDio(error));
    } on UpgradeRemoteException {
      rethrow;
    } on Object {
      throw const UpgradeRemoteException.invalidResponse();
    }
  }

  Options _options(String requestId) =>
      Options(extra: {NetworkRequestExtras.requestId: requestId});
}

class UpgradeRemoteException implements Exception {
  const UpgradeRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  UpgradeRemoteException.fromNetwork(NetworkException exception)
    : this._(UpgradeRemoteErrorKind.network, network: exception);

  UpgradeRemoteException.businessFailure(ApiBusinessFailure failure)
    : this._(UpgradeRemoteErrorKind.businessFailure, businessFailure: failure);

  const UpgradeRemoteException.invalidResponse()
    : this._(UpgradeRemoteErrorKind.invalidResponse);

  final UpgradeRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  int? get statusCode => network?.statusCode;
}

enum UpgradeRemoteErrorKind { network, businessFailure, invalidResponse }
