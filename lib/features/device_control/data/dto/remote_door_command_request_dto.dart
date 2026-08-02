import '../../domain/entities/remote_door_command.dart';

class RemoteDoorCommandRequestDto {
  const RemoteDoorCommandRequestDto({required this.action});

  final RemoteDoorCommandAction action;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'action': action.wireValue,
  };
}
