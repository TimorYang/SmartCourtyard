import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/account_overview.dart';
import '../../domain/repositories/account_overview_repository.dart';
import '../data_sources/account_overview_local_data_source.dart';
import '../data_sources/account_overview_remote_data_source.dart';
import '../mappers/account_overview_mapper.dart';

class AccountOverviewRepositoryImpl implements AccountOverviewRepository {
  AccountOverviewRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.logger,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AccountOverviewRemoteDataSource remoteDataSource;
  final AccountOverviewLocalDataSource localDataSource;
  final AppLogger logger;
  final DateTime Function() _clock;

  @override
  Future<AccountOverview?> readCachedOverview() async {
    return (await localDataSource.readOverview())?.toDomain();
  }

  @override
  Future<AccountOverview> refreshOverview({required String requestId}) async {
    try {
      final remoteOverview = await remoteDataSource.fetchOverview(
        requestId: requestId,
      );
      final overview = remoteOverview.toDomain(refreshedAt: _clock().toLocal());
      await localDataSource.saveOverview(overview.toCacheDto());
      logger.info('Account overview refreshed.', requestId: requestId);
      return overview;
    } on AccountOverviewRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to refresh account overview.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'statusCode': error.statusCode,
          'businessCode': error.businessFailure?.code,
          'businessMessageKey': error.businessFailure?.messageKey,
        },
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<void> clearCachedOverview() => localDataSource.clearOverview();

  AppError _mapError(AccountOverviewRemoteException error, String requestId) {
    if (error.kind == AccountOverviewRemoteErrorKind.network &&
        error.network != null) {
      return mapNetworkExceptionToAppError(
        error.network!,
        requestId: requestId,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'account.overview.failed',
      businessCode: error.businessFailure?.code,
      businessMessageKey: error.businessFailure?.messageKey,
      userMessage: error.kind == AccountOverviewRemoteErrorKind.businessFailure
          ? error.businessFailure?.message
          : null,
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }
}
