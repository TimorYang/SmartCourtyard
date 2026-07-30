import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/app_storage_paths.dart';
import '../../../core/logging/providers.dart';
import '../../../core/network/providers.dart';
import '../../../platform_bridge/providers.dart';
import '../data/data_sources/account_local_data_source.dart';
import '../data/data_sources/account_overview_api.dart';
import '../data/data_sources/account_profile_api.dart';
import '../data/data_sources/account_profile_remote_data_source.dart';
import '../data/data_sources/account_overview_local_data_source.dart';
import '../data/data_sources/account_overview_remote_data_source.dart';
import '../data/data_sources/account_secure_data_source.dart';
import '../data/data_sources/app_locale_local_data_source.dart';
import '../data/data_sources/managed_devices_api.dart';
import '../data/data_sources/managed_devices_remote_data_source.dart';
import '../data/data_sources/receiving_devices_api.dart';
import '../data/data_sources/receiving_devices_remote_data_source.dart';
import '../data/data_sources/shared_devices_api.dart';
import '../data/data_sources/shared_devices_remote_data_source.dart';
import '../data/repositories/app_locale_repository_impl.dart';
import '../data/repositories/app_language_options_repository_impl.dart';
import '../data/repositories/managed_devices_repository_impl.dart';
import '../data/repositories/account_repository_impl.dart';
import '../data/repositories/account_overview_repository_impl.dart';
import '../data/repositories/receiving_devices_repository_impl.dart';
import '../data/repositories/shared_devices_repository_impl.dart';
import '../data/repositories/system_permissions_repository_impl.dart';
import '../domain/entities/account_profile.dart';
import '../domain/entities/account_overview.dart';
import '../domain/entities/app_locale_preference.dart';
import '../domain/entities/app_language_option.dart';
import '../domain/entities/receiving_door.dart';
import '../domain/entities/shared_door.dart';
import '../domain/entities/shared_door_members.dart';
import '../domain/repositories/account_repository.dart';
import '../domain/repositories/account_overview_repository.dart';
import '../domain/repositories/app_locale_repository.dart';
import '../domain/repositories/app_language_options_repository.dart';
import '../domain/repositories/managed_devices_repository.dart';
import '../domain/repositories/receiving_devices_repository.dart';
import '../domain/repositories/system_permissions_repository.dart';
import '../domain/repositories/shared_devices_repository.dart';
import '../domain/use_cases/fetch_shared_doors_use_case.dart';
import '../domain/use_cases/fetch_managed_login_devices_use_case.dart';
import '../domain/use_cases/delete_shared_door_member_use_case.dart';
import '../domain/use_cases/fetch_receiving_doors_use_case.dart';
import '../domain/use_cases/open_system_permission_settings_use_case.dart';
import '../domain/use_cases/read_system_permissions_use_case.dart';
import '../domain/use_cases/request_system_permission_use_case.dart';
import '../domain/use_cases/remove_managed_login_device_use_case.dart';
import '../domain/use_cases/read_app_locale_preference_use_case.dart';
import '../domain/use_cases/save_app_locale_preference_use_case.dart';
import '../domain/use_cases/fetch_app_language_options_use_case.dart';
import '../domain/use_cases/confirm_account_deletion_use_case.dart';
import 'account_controller.dart';
import 'account_deletion_controller.dart';
import 'account_overview_controller.dart';
import 'app_locale_controller.dart';
import 'receiving_devices_controller.dart';
import 'shared_devices_controller.dart';
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

final accountProfileApiProvider = Provider<AccountProfileApi>(
  (ref) => AccountProfileApi(ref.watch(dioProvider)),
);
final accountProfileRemoteDataSourceProvider =
    Provider<AccountProfileRemoteDataSource>(
      (ref) => AccountProfileRemoteDataSourceImpl(
        api: ref.watch(accountProfileApiProvider),
      ),
    );

final accountOverviewLocalDataSourceProvider =
    Provider<AccountOverviewLocalDataSource>((ref) {
      if (AppStoragePaths.isFlutterTest) {
        return InMemoryAccountOverviewLocalDataSource();
      }
      final locations = ref.watch(appStorageLocationsProvider);
      if (locations == null) {
        return InMemoryAccountOverviewLocalDataSource();
      }
      return JsonFileAccountOverviewLocalDataSource(
        overviewFile: File(
          '${locations.persistentDirectory.path}/account_overview.json',
        ),
      );
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

final appLanguageOptionsRepositoryProvider =
    Provider<AppLanguageOptionsRepository>((ref) {
      return AppLanguageOptionsRepositoryImpl(
        remoteDataSource: ref.watch(accountProfileRemoteDataSourceProvider),
        logger: ref.watch(appLoggerProvider),
      );
    });

final fetchAppLanguageOptionsUseCaseProvider =
    Provider<FetchAppLanguageOptionsUseCase>((ref) {
      return FetchAppLanguageOptionsUseCase(
        repository: ref.watch(appLanguageOptionsRepositoryProvider),
      );
    });

final appLanguageOptionsProvider =
    FutureProvider.autoDispose<List<AppLanguageOption>>((ref) {
      return ref.watch(fetchAppLanguageOptionsUseCaseProvider)(
        requestId:
            'account-language-options-${DateTime.now().microsecondsSinceEpoch}',
      );
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
    remoteDataSource: ref.watch(accountProfileRemoteDataSourceProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final confirmAccountDeletionUseCaseProvider =
    Provider<ConfirmAccountDeletionUseCase>((ref) {
      return ConfirmAccountDeletionUseCase(
        ref.watch(accountRepositoryProvider),
      );
    });

final accountDeletionControllerProvider =
    AsyncNotifierProvider<AccountDeletionController, void>(
      AccountDeletionController.new,
    );

final accountOverviewApiProvider = Provider<AccountOverviewApi>((ref) {
  return AccountOverviewApi(ref.watch(dioProvider));
});

final accountOverviewRemoteDataSourceProvider =
    Provider<AccountOverviewRemoteDataSource>((ref) {
      return AccountOverviewRemoteDataSourceImpl(
        api: ref.watch(accountOverviewApiProvider),
      );
    });

final accountOverviewRepositoryProvider = Provider<AccountOverviewRepository>((
  ref,
) {
  return AccountOverviewRepositoryImpl(
    remoteDataSource: ref.watch(accountOverviewRemoteDataSourceProvider),
    localDataSource: ref.watch(accountOverviewLocalDataSourceProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final sharedDevicesApiProvider = Provider<SharedDevicesApi>((ref) {
  return SharedDevicesApi(ref.watch(dioProvider));
});

final sharedDevicesRemoteDataSourceProvider =
    Provider<SharedDevicesRemoteDataSource>((ref) {
      return SharedDevicesRemoteDataSourceImpl(
        api: ref.watch(sharedDevicesApiProvider),
      );
    });

final sharedDevicesRepositoryProvider = Provider<SharedDevicesRepository>((
  ref,
) {
  return SharedDevicesRepositoryImpl(
    remoteDataSource: ref.watch(sharedDevicesRemoteDataSourceProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final fetchSharedDoorsUseCaseProvider = Provider<FetchSharedDoorsUseCase>((
  ref,
) {
  return FetchSharedDoorsUseCase(
    repository: ref.watch(sharedDevicesRepositoryProvider),
  );
});

final sharedDevicesControllerProvider =
    AsyncNotifierProvider<SharedDevicesController, List<SharedDoor>>(
      SharedDevicesController.new,
    );

final managedDevicesApiProvider = Provider<ManagedDevicesApi>((ref) {
  return ManagedDevicesApi(ref.watch(dioProvider));
});

final managedDevicesRemoteDataSourceProvider =
    Provider<ManagedDevicesRemoteDataSource>((ref) {
      return ManagedDevicesRemoteDataSourceImpl(
        api: ref.watch(managedDevicesApiProvider),
      );
    });

final managedDevicesRepositoryProvider = Provider<ManagedDevicesRepository>((
  ref,
) {
  return ManagedDevicesRepositoryImpl(
    remoteDataSource: ref.watch(managedDevicesRemoteDataSourceProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final fetchManagedLoginDevicesUseCaseProvider =
    Provider<FetchManagedLoginDevicesUseCase>((ref) {
      return FetchManagedLoginDevicesUseCase(
        repository: ref.watch(managedDevicesRepositoryProvider),
      );
    });

final removeManagedLoginDeviceUseCaseProvider =
    Provider<RemoveManagedLoginDeviceUseCase>((ref) {
      return RemoveManagedLoginDeviceUseCase(
        repository: ref.watch(managedDevicesRepositoryProvider),
      );
    });

final sharedDoorMembersProvider = FutureProvider.autoDispose
    .family<SharedDoorMembers, int>((ref, doorId) {
      return ref
          .watch(sharedDevicesRepositoryProvider)
          .fetchDoorMembers(
            doorId: doorId,
            requestId:
                'shared-door-members-$doorId-${DateTime.now().toUtc().microsecondsSinceEpoch}',
          );
    });

final deleteSharedDoorMemberUseCaseProvider =
    Provider<DeleteSharedDoorMemberUseCase>(
      (ref) => DeleteSharedDoorMemberUseCase(
        repository: ref.watch(sharedDevicesRepositoryProvider),
      ),
    );

final receivingDevicesApiProvider = Provider<ReceivingDevicesApi>((ref) {
  return ReceivingDevicesApi(ref.watch(dioProvider));
});

final receivingDevicesRemoteDataSourceProvider =
    Provider<ReceivingDevicesRemoteDataSource>((ref) {
      return ReceivingDevicesRemoteDataSourceImpl(
        api: ref.watch(receivingDevicesApiProvider),
      );
    });

final receivingDevicesRepositoryProvider = Provider<ReceivingDevicesRepository>(
  (ref) {
    return ReceivingDevicesRepositoryImpl(
      remoteDataSource: ref.watch(receivingDevicesRemoteDataSourceProvider),
      logger: ref.watch(appLoggerProvider),
    );
  },
);

final fetchReceivingDoorsUseCaseProvider = Provider<FetchReceivingDoorsUseCase>(
  (ref) {
    return FetchReceivingDoorsUseCase(
      repository: ref.watch(receivingDevicesRepositoryProvider),
    );
  },
);

final receivingDevicesControllerProvider =
    AsyncNotifierProvider<ReceivingDevicesController, List<ReceivingDoor>>(
      ReceivingDevicesController.new,
    );

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

final accountOverviewControllerProvider =
    AsyncNotifierProvider<AccountOverviewController, AccountOverview?>(
      AccountOverviewController.new,
    );

final accountOverviewAutoRefreshProvider = Provider<bool>(
  (ref) => !AppStoragePaths.isFlutterTest,
);
