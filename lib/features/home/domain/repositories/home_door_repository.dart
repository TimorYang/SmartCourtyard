import '../../../../platform_bridge/hardware_models.dart';
import '../entities/home_door_cover_image.dart';

abstract interface class HomeDoorRepository {
  Future<List<DeviceSummary>> fetchDoors({
    required int sceneId,
    required String requestId,
  });

  Future<void> topDoor({required int doorId, required String requestId});

  Future<void> unbindDoor({required int doorId, required String requestId});

  Future<void> resetDoorCover({required int doorId, required String requestId});

  Future<void> updateDoorCover({
    required int doorId,
    required HomeDoorCoverImage image,
    required String requestId,
  });

  Future<void> renameDoor({
    required int doorId,
    required String name,
    required String requestId,
  });

  Future<void> moveDoorToScene({
    required int doorId,
    required int sceneId,
    required String requestId,
  });
}
