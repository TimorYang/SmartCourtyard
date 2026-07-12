import '../../../../core/network/access_token_cache.dart';
import '../../domain/entities/account_profile.dart';
import '../../domain/entities/account_token_set.dart';
import '../../domain/repositories/account_repository.dart';
import '../data_sources/account_local_data_source.dart';
import '../data_sources/account_secure_data_source.dart';
import '../mappers/account_profile_mapper.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl({
    required this.localDataSource,
    required this.secureDataSource,
  });

  final AccountLocalDataSource localDataSource;
  final AccountSecureDataSource secureDataSource;

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
  Future<void> clearAccount() async {
    await localDataSource.clearProfile();
    await secureDataSource.clearTokenSet();
    AccessTokenCache.clear();
  }

  @override
  Future<void> saveTokenSet(AccountTokenSet tokenSet) async {
    await secureDataSource.saveTokenSet(tokenSet);
    AccessTokenCache.set(tokenSet.accessToken);
  }

  @override
  Future<AccountTokenSet?> readTokenSet() async {
    final tokenSet = await secureDataSource.readTokenSet();
    if (tokenSet == null || !tokenSet.isUsableAt(DateTime.now())) {
      AccessTokenCache.clear();
    } else {
      AccessTokenCache.set(tokenSet.accessToken);
    }
    return tokenSet;
  }
}
