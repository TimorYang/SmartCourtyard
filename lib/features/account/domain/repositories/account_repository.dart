import '../entities/account_profile.dart';
import '../entities/account_avatar_code.dart';
import '../entities/account_token_set.dart';

abstract class AccountRepository {
  Future<AccountProfile?> readCachedProfile();

  Stream<AccountProfile?> watchProfile();

  Future<void> saveProfile(AccountProfile profile);

  Future<void> updateProfile({
    String? nickname,
    AccountAvatarCode? avatarCode,
    int? avatarFileId,
    required List<int>? avatarBytes,
    String? avatarFileName,
    required String requestId,
  }) => throw UnimplementedError();

  Future<void> clearAccount();

  Future<void> saveTokenSet(AccountTokenSet tokenSet);

  Future<AccountTokenSet?> readTokenSet();
}
