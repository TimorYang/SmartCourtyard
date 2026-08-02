import '../entities/remote_door_command.dart';
import '../repositories/remote_door_command_repository.dart';

class SubmitRemoteDoorCommandUseCase {
  const SubmitRemoteDoorCommandUseCase({required this.repository});

  final RemoteDoorCommandRepository repository;

  Future<RemoteDoorCommand> call({
    required String doorId,
    required RemoteDoorCommandAction action,
    required String requestId,
  }) {
    return repository.submitCommand(
      doorId: doorId,
      action: action,
      requestId: requestId,
    );
  }
}
