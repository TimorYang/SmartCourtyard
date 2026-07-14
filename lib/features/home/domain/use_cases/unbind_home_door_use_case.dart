import '../repositories/home_door_repository.dart';

class UnbindHomeDoorUseCase {
  const UnbindHomeDoorUseCase({required this.repository});

  final HomeDoorRepository repository;

  Future<void> call({required int doorId, required String requestId}) {
    return repository.unbindDoor(doorId: doorId, requestId: requestId);
  }
}
