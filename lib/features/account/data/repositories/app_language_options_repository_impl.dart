import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/network_app_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/app_language_option.dart';
import '../../domain/repositories/app_language_options_repository.dart';
import '../data_sources/account_profile_remote_data_source.dart';

class AppLanguageOptionsRepositoryImpl implements AppLanguageOptionsRepository {
  const AppLanguageOptionsRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final AccountProfileRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<List<AppLanguageOption>> fetchLanguageOptions({
    required String requestId,
  }) async {
    try {
      final options = await remoteDataSource.fetchLanguageOptions(
        requestId: requestId,
      );
      return options
          .where((option) => option.locale.trim().isNotEmpty)
          .map(
            (option) => AppLanguageOption(
              locale: option.locale.trim(),
              nativeName: option.nativeName.trim(),
            ),
          )
          .toList(growable: false);
    } on AccountProfileRemoteException catch (error, stackTrace) {
      logger.error(
        'Fetching app language options failed.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
      );
      if (error.network != null) {
        throw mapNetworkExceptionToAppError(
          error.network!,
          requestId: requestId,
        );
      }
      throw AppError(
        code: AppErrorCode.serverError,
        messageKey: 'account.languageOptionsFailed',
        businessCode: error.businessFailure?.code,
        businessMessageKey: error.businessFailure?.messageKey,
        userMessage: error.businessFailure?.message,
        action: AppErrorAction.retry,
        requestId: requestId,
        retryable: true,
      );
    }
  }
}
