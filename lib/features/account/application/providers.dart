import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/app_storage_paths.dart';
import '../../../platform_bridge/providers.dart';
import '../data/data_sources/account_local_data_source.dart';
import '../data/data_sources/account_secure_data_source.dart';
import '../data/data_sources/app_locale_local_data_source.dart';
import '../data/repositories/app_locale_repository_impl.dart';
import '../data/repositories/account_repository_impl.dart';
import '../data/repositories/system_permissions_repository_impl.dart';
import '../domain/entities/account_profile.dart';
import '../domain/entities/app_locale_preference.dart';
import '../domain/repositories/account_repository.dart';
import '../domain/repositories/app_locale_repository.dart';
import '../domain/repositories/system_permissions_repository.dart';
import '../domain/use_cases/open_system_permission_settings_use_case.dart';
import '../domain/use_cases/read_system_permissions_use_case.dart';
import '../domain/use_cases/request_system_permission_use_case.dart';
import '../domain/use_cases/read_app_locale_preference_use_case.dart';
import '../domain/use_cases/save_app_locale_preference_use_case.dart';
import 'account_controller.dart';
import 'app_locale_controller.dart';
export 'managed_devices_controller.dart';

final appStorageLocationsProvider = Provider<AppStorageLocations?>(
  (ref) => null,
);

final accountLocalDataSourceProvider = Provider<AccountLocalDataSource>((ref) {
  if (!AppStoragePaths.isFlutterTest) {
    final locations = ref.watch(appStorageLocationsProvider);
    if (locations == null) {
      return InMemoryAccountLocalDataSource();
    }
    return JsonFileAccountLocalDataSource(
      profileFile: File(
        '${locations.persistentDirectory.path}/account_profile.json',
      ),
      legacyProfileFiles: locations.legacyDirectories
          .map((directory) => File('${directory.path}/account_profile.json'))
          .toList(growable: false),
    );
  }

  return InMemoryAccountLocalDataSource();
});

final accountSecureDataSourceProvider = Provider<AccountSecureDataSource>((
  ref,
) {
  if (!AppStoragePaths.isFlutterTest) {
    final locations = ref.watch(appStorageLocationsProvider);
    if (locations == null) {
      return InMemoryAccountSecureDataSource();
    }
    return PlatformAccountSecureDataSource(
      storage: const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.unlocked_this_device,
        ),
      ),
      legacyPlaintextTokenFiles: locations.legacyDirectories
          .map((directory) => File('${directory.path}/account_token.json'))
          .toList(growable: false),
    );
  }

  return InMemoryAccountSecureDataSource();
});

final appLocaleLocalDataSourceProvider = Provider<AppLocaleLocalDataSource>((
  ref,
) {
  if (AppStoragePaths.isFlutterTest) {
    return InMemoryAppLocaleLocalDataSource();
  }
  final locations = ref.watch(appStorageLocationsProvider);
  if (locations == null) {
    return InMemoryAppLocaleLocalDataSource();
  }
  return JsonFileAppLocaleLocalDataSource(
    preferencesFile: File(
      '${locations.persistentDirectory.path}/app_locale_preference.json',
    ),
    legacyPreferenceFiles: locations.legacyDirectories
        .map(
          (directory) => File('${directory.path}/app_locale_preference.json'),
        )
        .toList(growable: false),
  );
});

final appLocaleRepositoryProvider = Provider<AppLocaleRepository>((ref) {
  return AppLocaleRepositoryImpl(ref.watch(appLocaleLocalDataSourceProvider));
});

final readAppLocalePreferenceUseCaseProvider =
    Provider<ReadAppLocalePreferenceUseCase>((ref) {
      return ReadAppLocalePreferenceUseCase(
        ref.watch(appLocaleRepositoryProvider),
      );
    });

final saveAppLocalePreferenceUseCaseProvider =
    Provider<SaveAppLocalePreferenceUseCase>((ref) {
      return SaveAppLocalePreferenceUseCase(
        ref.watch(appLocaleRepositoryProvider),
      );
    });

final appLocaleControllerProvider =
    AsyncNotifierProvider<AppLocaleController, AppLocalePreference>(
      AppLocaleController.new,
    );

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(
    localDataSource: ref.watch(accountLocalDataSourceProvider),
    secureDataSource: ref.watch(accountSecureDataSourceProvider),
  );
});

final systemPermissionsRepositoryProvider =
    Provider<SystemPermissionsRepository>((ref) {
      final gateway = AppStoragePaths.isFlutterTest
          ? ref.watch(hardwareGatewayProvider)
          : ref.watch(nativeHardwareGatewayProvider);
      return SystemPermissionsRepositoryImpl(gateway);
    });

final readSystemPermissionsUseCaseProvider =
    Provider<ReadSystemPermissionsUseCase>((ref) {
      return ReadSystemPermissionsUseCase(
        ref.watch(systemPermissionsRepositoryProvider),
      );
    });

final requestSystemPermissionUseCaseProvider =
    Provider<RequestSystemPermissionUseCase>((ref) {
      return RequestSystemPermissionUseCase(
        ref.watch(systemPermissionsRepositoryProvider),
      );
    });

final openSystemPermissionSettingsUseCaseProvider =
    Provider<OpenSystemPermissionSettingsUseCase>((ref) {
      return OpenSystemPermissionSettingsUseCase(
        ref.watch(systemPermissionsRepositoryProvider),
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
