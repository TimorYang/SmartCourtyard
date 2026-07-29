import '../../../../core/network/access_token_cache.dart';
import '../../domain/entities/account_profile.dart';
import '../../domain/entities/account_token_set.dart';
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
  });

  final AccountLocalDataSource localDataSource;
  final AccountSecureDataSource secureDataSource;
  final AccountProfileRemoteDataSource? remoteDataSource;

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
  Future<void> updateProfile({
    String? nickname,
    int? avatarFileId,
    required List<int>? avatarBytes,
    String? avatarFileName,
    required String requestId,
  }) async {
    final current = await readCachedProfile();
    if (current == null) throw StateError('No account profile');
    final source = remoteDataSource;
    if (source == null) {
      throw StateError('Account profile remote data source is unavailable');
    }
    final uploadedFileId = avatarBytes == null
        ? avatarFileId
        : await source.uploadImage(
            bytes: avatarBytes,
            fileName: avatarFileName ?? 'avatar.jpg',
            requestId: requestId,
          );
    await source.updateProfile(
      nickname: nickname,
      avatarFileId: uploadedFileId,
      requestId: requestId,
    );
    await saveProfile(
      current.copyWith(nickname: nickname, avatarFileId: uploadedFileId),
    );
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
}
