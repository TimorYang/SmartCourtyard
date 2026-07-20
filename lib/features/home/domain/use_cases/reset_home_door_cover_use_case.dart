import '../repositories/home_door_repository.dart';

class ResetHomeDoorCoverUseCase {
  const ResetHomeDoorCoverUseCase({required this.repository});

  final HomeDoorRepository repository;

  Future<void> call({required int doorId, required String requestId}) {
    return repository.resetDoorCover(doorId: doorId, requestId: requestId);
  }
}
