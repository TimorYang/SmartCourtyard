import '../entities/door_share.dart';
import '../repositories/door_share_repository.dart';

class FetchDoorShareCapabilitiesUseCase {
  const FetchDoorShareCapabilitiesUseCase({required this.repository});
  final DoorShareRepository repository;

  Future<List<ShareCapability>> call({
    required int doorId,
    required String requestId,
  }) => repository.fetchCapabilities(doorId: doorId, requestId: requestId);
}
