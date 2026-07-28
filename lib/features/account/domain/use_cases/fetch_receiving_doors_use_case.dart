import '../entities/receiving_door.dart';
import '../repositories/receiving_devices_repository.dart';

class FetchReceivingDoorsUseCase {
  const FetchReceivingDoorsUseCase({required this.repository});

  final ReceivingDevicesRepository repository;

  Future<List<ReceivingDoor>> call({required String requestId}) =>
      repository.fetchReceivingDoors(requestId: requestId);
}
