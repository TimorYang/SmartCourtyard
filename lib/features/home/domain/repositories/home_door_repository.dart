import '../../../../platform_bridge/hardware_models.dart';

abstract interface class HomeDoorRepository {
  Future<List<DeviceSummary>> fetchDoors({
    required int sceneId,
    required String requestId,
  });
}
