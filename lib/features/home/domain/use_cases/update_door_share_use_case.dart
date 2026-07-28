import '../entities/door_share.dart';
import '../repositories/door_share_repository.dart';

class UpdateDoorShareUseCase {
  const UpdateDoorShareUseCase({required this.repository});

  final DoorShareRepository repository;

  Future<void> call({
    required int shareId,
    required UpdateDoorShareCommand command,
    required String requestId,
  }) => repository.updateShare(
    shareId: shareId,
    command: command,
    requestId: requestId,
  );
}
