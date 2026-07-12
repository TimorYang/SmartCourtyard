import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/app_storage_paths.dart';
import '../data/data_sources/account_local_data_source.dart';
import '../data/data_sources/account_secure_data_source.dart';
import '../data/repositories/account_repository_impl.dart';
import '../domain/entities/account_profile.dart';
import '../domain/repositories/account_repository.dart';
import 'account_controller.dart';

final accountLocalDataSourceProvider = Provider<AccountLocalDataSource>((ref) {
  if (!AppStoragePaths.isFlutterTest) {
    final storageDirectory = AppStoragePaths.defaultStorageDirectory();
    return JsonFileAccountLocalDataSource(
      profileFile: File('${storageDirectory.path}/account_profile.json'),
    );
  }

  return InMemoryAccountLocalDataSource();
});

final accountSecureDataSourceProvider = Provider<AccountSecureDataSource>((
  ref,
) {
  if (!AppStoragePaths.isFlutterTest) {
    final storageDirectory = AppStoragePaths.defaultStorageDirectory();
    return PlatformAccountSecureDataSource(
      storage: const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.unlocked_this_device,
        ),
      ),
      legacyPlaintextTokenFile: File(
        '${storageDirectory.path}/account_token.json',
      ),
    );
  }

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
