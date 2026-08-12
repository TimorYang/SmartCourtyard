import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform_bridge/hardware_gateway.dart';
import '../../../platform_bridge/providers.dart';
import '../data/repositories/safety_sensor_management_repository_impl.dart';
import '../domain/repositories/safety_sensor_management_repository.dart';
import '../domain/use_cases/safety_sensor_management_delete_use_case.dart';
import '../domain/use_cases/safety_sensor_management_query_use_case.dart';

final safetySensorManagementHardwareGatewayProvider = Provider<HardwareGateway>(
  (ref) => ref.watch(nativeHardwareGatewayProvider),
);

final safetySensorManagementRepositoryProvider =
    Provider<SafetySensorManagementRepository>(
      (ref) => SafetySensorManagementRepositoryImpl(
        gateway: ref.watch(safetySensorManagementHardwareGatewayProvider),
      ),
    );

final safetySensorManagementQueryUseCaseProvider =
    Provider<SafetySensorManagementQueryUseCase>(
      (ref) => SafetySensorManagementQueryUseCase(
        repository: ref.watch(safetySensorManagementRepositoryProvider),
      ),
    );

final safetySensorManagementDeleteUseCaseProvider =
    Provider<SafetySensorManagementDeleteUseCase>(
      (ref) => SafetySensorManagementDeleteUseCase(
        repository: ref.watch(safetySensorManagementRepositoryProvider),
      ),
    );
