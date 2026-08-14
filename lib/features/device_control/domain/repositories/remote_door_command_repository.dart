import '../entities/remote_door_command.dart';

abstract interface class RemoteDoorCommandRepository {
  Future<RemoteDoorCommand> submitCommand({
    required String doorId,
    required RemoteDoorCommandAction action,
    required String requestId,
  });
}
