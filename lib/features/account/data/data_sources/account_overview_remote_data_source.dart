import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/account_overview_dto.dart';
import 'account_overview_api.dart';

abstract interface class AccountOverviewRemoteDataSource {
  Future<AccountOverviewDto> fetchOverview({required String requestId});
}

class AccountOverviewRemoteDataSourceImpl
    implements AccountOverviewRemoteDataSource {
  AccountOverviewRemoteDataSourceImpl({required this.api});

  final AccountOverviewApi api;

  @override
  Future<AccountOverviewDto> fetchOverview({required String requestId}) async {
    try {
      final response = await api.fetchOverview(
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (!response.isBusinessSuccess) {
        throw AccountOverviewRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const AccountOverviewRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw AccountOverviewRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on AccountOverviewRemoteException {
      rethrow;
    } on FormatException {
      throw const AccountOverviewRemoteException.invalidResponse();
    }
  }
}

class AccountOverviewRemoteException implements Exception {
  const AccountOverviewRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });

  AccountOverviewRemoteException.fromNetwork(NetworkException exception)
    : this._(AccountOverviewRemoteErrorKind.network, network: exception);

  AccountOverviewRemoteException.businessFailure(ApiBusinessFailure failure)
    : this._(
        AccountOverviewRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );

  const AccountOverviewRemoteException.invalidResponse()
    : this._(AccountOverviewRemoteErrorKind.invalidResponse);

  final AccountOverviewRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  int? get statusCode => network?.statusCode;
}

enum AccountOverviewRemoteErrorKind {
  network,
  businessFailure,
  invalidResponse,
}
