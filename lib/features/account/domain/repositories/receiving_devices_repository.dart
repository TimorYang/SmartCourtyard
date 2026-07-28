import '../entities/receiving_door.dart';

abstract interface class ReceivingDevicesRepository {
  Future<List<ReceivingDoor>> fetchReceivingDoors({required String requestId});
}
