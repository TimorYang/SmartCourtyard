import '../entities/managed_login_device.dart';

abstract interface class ManagedDevicesRepository {
  Future<List<ManagedLoginDevice>> fetchLoginDevices({
    required String requestId,
  });

  Future<void> removeLoginDevice({
    required String sessionId,
    required String requestId,
  });
}
