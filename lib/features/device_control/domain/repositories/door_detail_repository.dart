import '../entities/door_detail.dart';
import '../entities/door_device.dart';

abstract interface class DoorDetailRepository {
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  });

  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  });
}
