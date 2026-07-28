import '../entities/shared_door.dart';
import '../entities/shared_door_members.dart';

abstract interface class SharedDevicesRepository {
  Future<List<SharedDoor>> fetchSharedDoors({required String requestId});
  Future<SharedDoorMembers> fetchDoorMembers({required int doorId, required String requestId});
  Future<void> deleteDoorMember({required int shareId, required String requestId});
}
