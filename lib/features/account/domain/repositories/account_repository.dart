import '../entities/account_profile.dart';
import '../entities/account_avatar_code.dart';
import '../entities/account_token_set.dart';
import '../entities/region_option.dart';

abstract class AccountRepository {
  Future<AccountProfile?> readCachedProfile();

  Stream<AccountProfile?> watchProfile();

  Future<void> saveProfile(AccountProfile profile);

  Future<AccountProfile> refreshProfile({required String requestId});

  Future<List<RegionOption>> fetchRegionOptions({required String requestId});

  Future<void> updateProfile({
    String? nickname,
    AccountAvatarCode? avatarCode,
    int? avatarFileId,
    String? regionCode,
    String? locale,
    required List<int>? avatarBytes,
    String? avatarFileName,
    required String requestId,
  }) => throw UnimplementedError();

  Future<void> confirmAccountDeletion({required String requestId});

  Future<void> clearAccount();

  Future<void> saveTokenSet(AccountTokenSet tokenSet);

  Future<AccountTokenSet?> readTokenSet();
}
