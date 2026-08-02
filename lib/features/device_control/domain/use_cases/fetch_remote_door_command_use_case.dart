import '../entities/remote_door_command.dart';
import '../repositories/remote_door_command_repository.dart';

class FetchRemoteDoorCommandUseCase {
  const FetchRemoteDoorCommandUseCase({required this.repository});

  final RemoteDoorCommandRepository repository;

  Future<RemoteDoorCommand> call({
    required String doorId,
    required String commandId,
    required String requestId,
  }) {
    return repository.fetchCommand(
      doorId: doorId,
      commandId: commandId,
      requestId: requestId,
    );
  }
}
