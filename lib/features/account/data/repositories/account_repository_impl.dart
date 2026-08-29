import '../../../../core/network/access_token_cache.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/network_exception.dart';
import '../../domain/entities/account_profile.dart';
import '../../domain/entities/account_avatar_code.dart';
import '../../domain/entities/account_token_set.dart';
import '../../domain/entities/region_option.dart';
import '../../domain/repositories/account_repository.dart';
import '../data_sources/account_local_data_source.dart';
import '../data_sources/account_secure_data_source.dart';
import '../mappers/account_profile_mapper.dart';
import '../data_sources/account_profile_remote_data_source.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl({
    required this.localDataSource,
    required this.secureDataSource,
    this.remoteDataSource,
    this.logger,
  });

  final AccountLocalDataSource localDataSource;
  final AccountSecureDataSource secureDataSource;
  final AccountProfileRemoteDataSource? remoteDataSource;
  final AppLogger? logger;

  @override
  Future<AccountProfile?> readCachedProfile() async {
    final dto = await localDataSource.readProfile();
    return dto?.toDomain();
  }

  @override
  Stream<AccountProfile?> watchProfile() {
    return localDataSource.watchProfile().map((dto) => dto?.toDomain());
  }

  @override
  Future<void> saveProfile(AccountProfile profile) {
    return localDataSource.saveProfile(profile.toLocalDto());
  }

  @override
  Future<AccountProfile> refreshProfile({required String requestId}) async {
    final source = _requireRemoteDataSource();
    try {
      final cachedProfile = await readCachedProfile();
      final profile = (await source.fetchProfile(
        requestId: requestId,
      )).toDomain(cachedProfile: cachedProfile);
      await saveProfile(profile);
      return profile;
    } on AccountProfileRemoteException catch (error, stackTrace) {
      throw _mapRemoteError(error, requestId, stackTrace);
    }
  }

  @override
  Future<List<RegionOption>> fetchRegionOptions({
    required String requestId,
  }) async {
    final source = _requireRemoteDataSource();
    try {
      return (await source.fetchRegionOptions(requestId: requestId))
          .where((option) => option.regionCode.trim().isNotEmpty)
          .map(
            (option) => RegionOption(
              code: option.regionCode.trim(),
              displayName: option.displayName.trim().isEmpty
                  ? option.regionCode.trim()
                  : option.displayName.trim(),
            ),
          )
          .toList(growable: false);
    } on AccountProfileRemoteException catch (error, stackTrace) {
      throw _mapRemoteError(error, requestId, stackTrace);
    }
  }

  @override
  Future<void> updateProfile({
    String? nickname,
    AccountAvatarCode? avatarCode,
    int? avatarFileId,
    String? regionCode,
    String? locale,
    required List<int>? avatarBytes,
    String? avatarFileName,
    required String requestId,
  }) async {
    final source = _requireRemoteDataSource();
    if (avatarCode != null && (avatarFileId != null || avatarBytes != null)) {
      throw ArgumentError(
        'avatarCode and avatarFileId are mutually exclusive.',
      );
    }
    try {
      final uploadedFileId = avatarBytes == null
          ? avatarFileId
          : await source.uploadImage(
              bytes: avatarBytes,
              fileName: avatarFileName ?? 'avatar.jpg',
              requestId: requestId,
            );
      final isAvatarOnlyUpdate =
          nickname == null &&
          regionCode == null &&
          locale == null &&
          (avatarCode != null || uploadedFileId != null);
      if (isAvatarOnlyUpdate) {
        await source.updateAvatar(
          avatarCode: avatarCode,
          avatarFileId: uploadedFileId,
          requestId: requestId,
        );
      } else if (nickname != null && regionCode == null && locale == null) {
        await source.updateNickname(nickname: nickname, requestId: requestId);
      } else if (regionCode != null && nickname == null && locale == null) {
        await source.updateRegion(regionCode: regionCode, requestId: requestId);
      } else if (locale != null && nickname == null && regionCode == null) {
        await source.updateLanguage(locale: locale, requestId: requestId);
      } else {
        await source.updateProfile(
          nickname: nickname,
          avatarCode: avatarCode,
          avatarFileId: uploadedFileId,
          regionCode: regionCode,
          locale: locale,
          requestId: requestId,
        );
      }
      await refreshProfile(requestId: requestId);
    } on AccountProfileRemoteException catch (error, stackTrace) {
      throw _mapRemoteError(error, requestId, stackTrace);
    }
  }

  @override
  Future<void> confirmAccountDeletion({required String requestId}) async {
    final source = _requireRemoteDataSource();
    try {
      await source.confirmAccountDeletion(requestId: requestId);
    } on AccountProfileRemoteException catch (error, stackTrace) {
      throw _mapRemoteError(
        error,
        requestId,
        stackTrace,
        messageKey: 'account.deletionFailed',
      );
    }
  }

  @override
  Future<void> clearAccount() async {
    await localDataSource.clearProfile();
    await secureDataSource.clearTokenSet();
    AccessTokenCache.clear();
  }

  @override
  Future<void> saveTokenSet(AccountTokenSet tokenSet) async {
    await secureDataSource.saveTokenSet(tokenSet);
    AccessTokenCache.set(tokenSet.accessToken, expiresAt: tokenSet.expiresAt);
  }

  @override
  Future<AccountTokenSet?> readTokenSet() async {
    final tokenSet = await secureDataSource.readTokenSet();
    if (tokenSet == null || !tokenSet.hasAccessToken) {
      AccessTokenCache.clear();
    } else {
      AccessTokenCache.set(tokenSet.accessToken, expiresAt: tokenSet.expiresAt);
    }
    return tokenSet;
  }

  AccountProfileRemoteDataSource _requireRemoteDataSource() {
    final source = remoteDataSource;
    if (source == null) {
      throw StateError('Account profile remote data source is unavailable');
    }
    return source;
  }

  AppError _mapRemoteError(
    AccountProfileRemoteException error,
    String requestId,
    StackTrace stackTrace, {
    String messageKey = 'account.profileRequestFailed',
  }) {
    logger?.error(
      'Account profile request failed.',
      requestId: requestId,
      error: error,
      stackTrace: stackTrace,
      context: {'statusCode': error.network?.statusCode},
    );
    return AppError(
      code: error.network == null
          ? AppErrorCode.serverError
          : error.network?.statusCode == 401 || error.network?.statusCode == 403
          ? AppErrorCode.accessDenied
          : error.network?.category == NetworkFailureCategory.networkUnavailable
          ? AppErrorCode.networkUnavailable
          : AppErrorCode.serverError,
      messageKey: messageKey,
      userMessage: error.businessFailure?.message,
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }
}
