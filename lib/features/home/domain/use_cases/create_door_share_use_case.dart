import '../entities/door_share.dart';
import '../repositories/door_share_repository.dart';

class CreateDoorShareUseCase {
  const CreateDoorShareUseCase({required this.repository});
  final DoorShareRepository repository;

  Future<void> call({
    required int doorId,
    required CreateDoorShareCommand command,
    required String requestId,
  }) => repository.createShare(
    doorId: doorId,
    command: command,
    requestId: requestId,
  );
}
