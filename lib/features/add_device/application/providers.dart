import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/providers.dart';
import '../../../core/network/providers.dart';
import '../../../platform_bridge/hardware_gateway.dart';
import '../../../platform_bridge/providers.dart';
import '../data/data_sources/add_device_onboarding_api.dart';
import '../data/data_sources/add_device_onboarding_remote_data_source.dart';
import '../data/repositories/add_device_onboarding_repository_impl.dart';
import '../domain/repositories/add_device_onboarding_repository.dart';
import '../domain/use_cases/add_force_door_use_case.dart';
import '../domain/use_cases/fetch_onboarding_device_key_use_case.dart';
import 'add_device_controller.dart';

final addDeviceHardwareGatewayProvider = Provider<HardwareGateway>((ref) {
  return ref.watch(nativeHardwareGatewayProvider);
});

final addDeviceOnboardingApiProvider = Provider<AddDeviceOnboardingApi>((ref) {
  return AddDeviceOnboardingApi(ref.watch(dioProvider));
});

final addDeviceOnboardingRemoteDataSourceProvider =
    Provider<AddDeviceOnboardingRemoteDataSource>((ref) {
      return AddDeviceOnboardingRemoteDataSourceImpl(
        api: ref.watch(addDeviceOnboardingApiProvider),
      );
    });

final addDeviceOnboardingRepositoryProvider =
    Provider<AddDeviceOnboardingRepository>((ref) {
      return AddDeviceOnboardingRepositoryImpl(
        remoteDataSource: ref.watch(
          addDeviceOnboardingRemoteDataSourceProvider,
        ),
        logger: ref.watch(appLoggerProvider),
      );
    });

final fetchOnboardingDeviceKeyUseCaseProvider =
    Provider<FetchOnboardingDeviceKeyUseCase>((ref) {
      return FetchOnboardingDeviceKeyUseCase(
        repository: ref.watch(addDeviceOnboardingRepositoryProvider),
      );
    });

final addForceDoorUseCaseProvider = Provider<AddForceDoorUseCase>((ref) {
  return AddForceDoorUseCase(
    repository: ref.watch(addDeviceOnboardingRepositoryProvider),
  );
});

final addDeviceControllerProvider =
    NotifierProvider<AddDeviceController, AddDeviceState>(
      AddDeviceController.new,
    );
