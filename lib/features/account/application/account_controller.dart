import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/account_profile.dart';
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

  void setSessionProfile(AccountProfile profile) {
    state = AsyncData(profile);
  }

  Future<void> clearAccount() async {
    state = const AsyncData<AccountProfile?>(null);
    await _repository.clearAccount();
  }
}
