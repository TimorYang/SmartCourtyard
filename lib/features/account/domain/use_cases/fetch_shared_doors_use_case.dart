import '../entities/shared_door.dart';
import '../repositories/shared_devices_repository.dart';

class FetchSharedDoorsUseCase {
  const FetchSharedDoorsUseCase({required this.repository});

  final SharedDevicesRepository repository;

  Future<List<SharedDoor>> call({required String requestId}) =>
      repository.fetchSharedDoors(requestId: requestId);
}
