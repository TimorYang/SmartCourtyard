import '../entities/device_capability.dart';
import '../repositories/device_capability_repository.dart';

class FetchDeviceCapabilitiesUseCase {
  const FetchDeviceCapabilitiesUseCase(this._repository);

  final DeviceCapabilityRepository _repository;

  Future<List<DeviceCapability>> call({
    required String deviceId,
    required String requestId,
  }) => _repository.fetchCapabilities(deviceId: deviceId, requestId: requestId);
}
