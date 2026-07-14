import '../entities/door_detail.dart';

abstract interface class DoorDetailRepository {
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  });
}
