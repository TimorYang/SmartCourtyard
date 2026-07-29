import '../repositories/managed_devices_repository.dart';

class RemoveManagedLoginDeviceUseCase {
  const RemoveManagedLoginDeviceUseCase({required this.repository});

  final ManagedDevicesRepository repository;

  Future<void> call({required String sessionId, required String requestId}) =>
      repository.removeLoginDevice(sessionId: sessionId, requestId: requestId);
}
