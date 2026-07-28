import '../entities/door_share.dart';

abstract interface class DoorShareRepository {
  Future<List<ShareCapability>> fetchCapabilities({
    required int doorId,
    required String requestId,
  });

  Future<void> createShare({
    required int doorId,
    required CreateDoorShareCommand command,
    required String requestId,
  });
  Future<void> updateShare({
    required int shareId,
    required UpdateDoorShareCommand command,
    required String requestId,
  });
}
