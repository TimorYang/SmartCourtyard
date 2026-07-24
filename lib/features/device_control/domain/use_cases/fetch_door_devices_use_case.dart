import '../entities/door_device.dart';
import '../repositories/door_detail_repository.dart';

class FetchDoorDevicesUseCase {
  const FetchDoorDevicesUseCase({required this.repository});

  final DoorDetailRepository repository;

  Future<List<DoorDevice>> call({
    required String doorId,
    required String requestId,
  }) => repository.fetchDoorDevices(doorId: doorId, requestId: requestId);
}
