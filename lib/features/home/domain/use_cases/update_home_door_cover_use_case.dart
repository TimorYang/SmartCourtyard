import '../entities/home_door_cover_image.dart';
import '../repositories/home_door_repository.dart';

class UpdateHomeDoorCoverUseCase {
  const UpdateHomeDoorCoverUseCase({required this.repository});

  final HomeDoorRepository repository;

  Future<void> call({
    required int doorId,
    required HomeDoorCoverImage image,
    required String requestId,
  }) {
    return repository.updateDoorCover(
      doorId: doorId,
      image: image,
      requestId: requestId,
    );
  }
}
