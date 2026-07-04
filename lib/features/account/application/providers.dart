import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data_sources/account_local_data_source.dart';
import '../data/data_sources/account_secure_data_source.dart';
import '../data/repositories/account_repository_impl.dart';
import '../domain/entities/account_profile.dart';
import '../domain/repositories/account_repository.dart';
import 'account_controller.dart';

final accountLocalDataSourceProvider = Provider<AccountLocalDataSource>((ref) {
  return InMemoryAccountLocalDataSource();
});

final accountSecureDataSourceProvider = Provider<AccountSecureDataSource>((
  ref,
) {
  return InMemoryAccountSecureDataSource();
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(
    localDataSource: ref.watch(accountLocalDataSourceProvider),
    secureDataSource: ref.watch(accountSecureDataSourceProvider),
  );
});

final cachedAccountProfileProvider = FutureProvider<AccountProfile?>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.readCachedProfile();
});

final accountProfileChangesProvider = StreamProvider<AccountProfile?>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchProfile();
});

final accountControllerProvider =
    AsyncNotifierProvider<AccountController, AccountProfile?>(
      AccountController.new,
    );
