import '../entities/managed_login_device.dart';
import '../repositories/managed_devices_repository.dart';

class FetchManagedLoginDevicesUseCase {
  const FetchManagedLoginDevicesUseCase({required this.repository});

  final ManagedDevicesRepository repository;

  Future<List<ManagedLoginDevice>> call({required String requestId}) =>
      repository.fetchLoginDevices(requestId: requestId);
}
