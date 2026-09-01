import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';

import '../domain/entities/account_profile.dart';
import '../domain/entities/account_avatar_code.dart';
import '../domain/repositories/account_repository.dart';
import 'providers.dart';

class AccountController extends AsyncNotifier<AccountProfile?> {
  late final AccountRepository _repository;
  AppError? _lastUpdateError;

  AppError? get lastUpdateError => _lastUpdateError;

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

  Future<bool> updateRegion(String regionCode) =>
      _update(regionCode: regionCode.trim());

  Future<bool> updateLocale(String locale) => _update(locale: locale.trim());

  Future<bool> refreshProfile() async {
    if (state.isLoading) return false;
    final current = state.whenOrNull(data: (value) => value);
    try {
      final profile = await _repository.refreshProfile(
        requestId:
            'account-profile-refresh-${DateTime.now().microsecondsSinceEpoch}',
      );
      state = AsyncData(profile);
      return true;
    } catch (_) {
      if (current != null) {
        state = AsyncData(current);
      }
      return false;
    }
  }

  Future<bool> _update({
    String? nickname,
    AccountAvatarCode? avatarCode,
    List<int>? avatarBytes,
    String? avatarFileName,
    String? regionCode,
    String? locale,
  }) async {
    if (state.isLoading ||
        (nickname?.isEmpty ?? false) ||
        (regionCode?.isEmpty ?? false) ||
        (locale?.isEmpty ?? false)) {
      return false;
    }
    final current = state.whenOrNull(data: (value) => value);
    _lastUpdateError = null;
    state = const AsyncLoading<AccountProfile?>();
    try {
      await _repository.updateProfile(
        nickname: nickname,
        avatarCode: avatarCode,
        avatarBytes: avatarBytes,
        avatarFileName: avatarFileName,
        regionCode: regionCode,
        locale: locale,
        requestId: 'account-profile-${DateTime.now().microsecondsSinceEpoch}',
      );
      state = AsyncData(await _repository.readCachedProfile());
      return true;
    } catch (error, stackTrace) {
      _lastUpdateError = error is AppError ? error : null;
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
