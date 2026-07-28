import '../repositories/shared_devices_repository.dart';

class DeleteSharedDoorMemberUseCase {
  const DeleteSharedDoorMemberUseCase({required this.repository});
  final SharedDevicesRepository repository;

  Future<void> call({required int shareId, required String requestId}) =>
      repository.deleteDoorMember(shareId: shareId, requestId: requestId);
}
