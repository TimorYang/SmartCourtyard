import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/account_profile.dart';
import '../domain/entities/account_avatar_code.dart';
import '../domain/repositories/account_repository.dart';
import 'providers.dart';

class AccountController extends AsyncNotifier<AccountProfile?> {
  late final AccountRepository _repository;

  @override
  Future<AccountProfile?> build() async {
    _repository = ref.watch(accountRepositoryProvider);
    return _repository.readCachedProfile();
  }

  Future<void> saveProfile(AccountProfile profile) async {
    state = AsyncData(profile);
    try {
      await _repository.saveProfile(profile);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<bool> updateNickname(String value) => _update(nickname: value.trim());

  Future<bool> updateAvatar(List<int> bytes, String fileName) =>
      _update(avatarBytes: bytes, avatarFileName: fileName);

  Future<bool> updateAvatarCode(AccountAvatarCode avatarCode) =>
      _update(avatarCode: avatarCode);

  Future<bool> _update({
    String? nickname,
    AccountAvatarCode? avatarCode,
    List<int>? avatarBytes,
    String? avatarFileName,
  }) async {
    if (state.isLoading || (nickname?.isEmpty ?? false)) return false;
    final current = state.whenOrNull(data: (value) => value);
    if (current == null) return false;
    state = const AsyncLoading<AccountProfile?>();
    try {
      await _repository.updateProfile(
        nickname: nickname,
        avatarCode: avatarCode,
        avatarBytes: avatarBytes,
        avatarFileName: avatarFileName,
        requestId: 'account-profile-${DateTime.now().microsecondsSinceEpoch}',
      );
      state = AsyncData(await _repository.readCachedProfile());
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(current);
      return false;
    }
  }

  void setSessionProfile(AccountProfile profile) {
    state = AsyncData(profile);
  }

  Future<void> clearAccount() async {
    state = const AsyncData<AccountProfile?>(null);
    await _repository.clearAccount();
    await ref.read(accountOverviewRepositoryProvider).clearCachedOverview();
  }
}
