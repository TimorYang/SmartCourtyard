import '../repositories/home_door_repository.dart';

class RenameHomeDoorUseCase {
  const RenameHomeDoorUseCase({required this.repository});

  final HomeDoorRepository repository;

  Future<void> call({
    required int doorId,
    required String name,
    required String requestId,
  }) {
    return repository.renameDoor(
      doorId: doorId,
      name: name,
      requestId: requestId,
    );
  }
}
