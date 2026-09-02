import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../../../core/logging/providers.dart';
import '../../../core/storage/app_storage_paths.dart';
import '../../auth/application/login_device_context_provider.dart';
import '../../auth/domain/services/login_device_context_provider.dart';
import '../../../platform_bridge/hardware_gateway.dart';
import '../../../platform_bridge/providers.dart';
import '../data/engage_lab_push_gateway.dart';
import '../data/data_sources/engage_lab_push_api.dart';
import '../data/data_sources/engage_lab_push_remote_data_source.dart';
import '../data/noop_push_gateway.dart';
import '../data/repositories/push_registration_repository_impl.dart';
import '../domain/entities/push_configuration.dart';
import '../domain/services/push_gateway.dart';
import '../domain/repositories/push_registration_repository.dart';
import '../domain/use_cases/bind_push_registration_use_case.dart';
import '../domain/use_cases/unbind_push_registration_use_case.dart';
import 'push_registration_sync_guard.dart';

final pushConfigurationProvider = Provider<PushConfiguration>((ref) {
  return PushConfiguration.fromEnvironment;
});

final pushGatewayProvider = Provider<PushGateway>((ref) {
  if (AppStoragePaths.isFlutterTest) {
    return const NoopPushGateway();
  }
  return EngageLabPushGateway(logger: ref.watch(appLoggerProvider));
});

final pushHardwareGatewayProvider = Provider<HardwareGateway>((ref) {
  return AppStoragePaths.isFlutterTest
      ? ref.watch(hardwareGatewayProvider)
      : ref.watch(nativeHardwareGatewayProvider);
});

final engageLabPushApiProvider = Provider<EngageLabPushApi>((ref) {
  return EngageLabPushApi(ref.watch(dioProvider));
});

final engageLabPushRemoteDataSourceProvider =
    Provider<EngageLabPushRemoteDataSource>((ref) {
      return EngageLabPushRemoteDataSourceImpl(
        api: ref.watch(engageLabPushApiProvider),
      );
    });

final pushRegistrationRepositoryProvider = Provider<PushRegistrationRepository>(
  (ref) {
    return PushRegistrationRepositoryImpl(
      remoteDataSource: ref.watch(engageLabPushRemoteDataSourceProvider),
      logger: ref.watch(appLoggerProvider),
    );
  },
);

final bindPushRegistrationUseCaseProvider =
    Provider<BindPushRegistrationUseCase>((ref) {
      return BindPushRegistrationUseCase(
        repository: ref.watch(pushRegistrationRepositoryProvider),
      );
    });

final unbindPushRegistrationUseCaseProvider =
    Provider<UnbindPushRegistrationUseCase>((ref) {
      return UnbindPushRegistrationUseCase(
        repository: ref.watch(pushRegistrationRepositoryProvider),
      );
    });

/// Push reuses the same stable installation identifier used by login.
final pushRegistrationContextProvider = Provider<LoginDeviceContextProvider>((
  ref,
) {
  return ref.watch(loginDeviceContextProvider);
});

final pushRegistrationSyncGuardProvider = Provider<PushRegistrationSyncGuard>((
  ref,
) {
  return PushRegistrationSyncGuard();
});
