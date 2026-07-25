import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/providers.dart';
import '../../../core/network/providers.dart';
import '../../../platform_bridge/hardware_gateway.dart';
import '../../../platform_bridge/providers.dart';
import '../data/data_sources/device_capability_api.dart';
import '../data/data_sources/device_capability_remote_data_source.dart';
import '../data/data_sources/door_settings_api.dart';
import '../data/data_sources/door_settings_remote_data_source.dart';
import '../data/repositories/device_capability_repository_impl.dart';
import '../data/repositories/device_settings_repository_impl.dart';
import '../data/repositories/door_settings_repository_impl.dart';
import '../domain/repositories/device_capability_repository.dart';
import '../domain/repositories/device_settings_repository.dart';
import '../domain/repositories/door_settings_repository.dart';
import '../domain/use_cases/fetch_device_capabilities_use_case.dart';
import '../domain/use_cases/fetch_door_settings_use_case.dart';
import '../domain/use_cases/query_device_settings_use_case.dart';
import '../domain/use_cases/set_device_setting_use_case.dart';

final deviceSettingsHardwareGatewayProvider = Provider<HardwareGateway>((ref) {
  return ref.watch(nativeHardwareGatewayProvider);
});

final deviceSettingsRepositoryProvider = Provider<DeviceSettingsRepository>((
  ref,
) {
  return DeviceSettingsRepositoryImpl(
    ref.watch(deviceSettingsHardwareGatewayProvider),
  );
});

final deviceCapabilityApiProvider = Provider<DeviceCapabilityApi>((ref) {
  return DeviceCapabilityApi(ref.watch(dioProvider));
});

final deviceCapabilityRemoteDataSourceProvider =
    Provider<DeviceCapabilityRemoteDataSource>((ref) {
      return DeviceCapabilityRemoteDataSourceImpl(
        api: ref.watch(deviceCapabilityApiProvider),
      );
    });

final deviceCapabilityRepositoryProvider = Provider<DeviceCapabilityRepository>(
  (ref) => DeviceCapabilityRepositoryImpl(
    remoteDataSource: ref.watch(deviceCapabilityRemoteDataSourceProvider),
    logger: ref.watch(appLoggerProvider),
  ),
);

final fetchDeviceCapabilitiesUseCaseProvider =
    Provider<FetchDeviceCapabilitiesUseCase>(
      (ref) => FetchDeviceCapabilitiesUseCase(
        ref.watch(deviceCapabilityRepositoryProvider),
      ),
    );

final doorSettingsApiProvider = Provider<DoorSettingsApi>((ref) {
  return DoorSettingsApi(ref.watch(dioProvider));
});

final doorSettingsRemoteDataSourceProvider =
    Provider<DoorSettingsRemoteDataSource>((ref) {
      return DoorSettingsRemoteDataSourceImpl(
        api: ref.watch(doorSettingsApiProvider),
      );
    });

final doorSettingsRepositoryProvider = Provider<DoorSettingsRepository>((ref) {
  return DoorSettingsRepositoryImpl(
    remoteDataSource: ref.watch(doorSettingsRemoteDataSourceProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final fetchDoorSettingsUseCaseProvider = Provider<FetchDoorSettingsUseCase>(
  (ref) => FetchDoorSettingsUseCase(ref.watch(doorSettingsRepositoryProvider)),
);

final queryDeviceSettingsUseCaseProvider = Provider<QueryDeviceSettingsUseCase>(
  (ref) {
    return QueryDeviceSettingsUseCase(
      ref.watch(deviceSettingsRepositoryProvider),
    );
  },
);

final setDeviceSettingUseCaseProvider = Provider<SetDeviceSettingUseCase>((
  ref,
) {
  return SetDeviceSettingUseCase(ref.watch(deviceSettingsRepositoryProvider));
});
