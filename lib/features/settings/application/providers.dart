import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform_bridge/hardware_gateway.dart';
import '../../../platform_bridge/providers.dart';
import '../data/repositories/device_settings_repository_impl.dart';
import '../domain/repositories/device_settings_repository.dart';
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
