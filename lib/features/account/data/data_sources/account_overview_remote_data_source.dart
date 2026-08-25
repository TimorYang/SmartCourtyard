import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
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
      if ((response.code != 0 && response.code != 200) ||
          !response.success ||
          data == null) {
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
  const AccountOverviewRemoteException._(this.kind, {this.statusCode});

  AccountOverviewRemoteException.fromNetwork(NetworkException exception)
    : this._(
        AccountOverviewRemoteErrorKind.network,
        statusCode: exception.statusCode,
      );

  const AccountOverviewRemoteException.invalidResponse()
    : this._(AccountOverviewRemoteErrorKind.invalidResponse);

  final AccountOverviewRemoteErrorKind kind;
  final int? statusCode;
}

enum AccountOverviewRemoteErrorKind { network, invalidResponse }
