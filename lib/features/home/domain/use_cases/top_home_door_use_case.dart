import '../repositories/home_door_repository.dart';

class TopHomeDoorUseCase {
  const TopHomeDoorUseCase({required this.repository});

  final HomeDoorRepository repository;

  Future<void> call({required int doorId, required String requestId}) {
    return repository.topDoor(doorId: doorId, requestId: requestId);
  }
}
