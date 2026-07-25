import '../entities/device_capability.dart';

abstract interface class DeviceCapabilityRepository {
  Future<List<DeviceCapability>> fetchCapabilities({
    required String deviceId,
    required String requestId,
  });
}
