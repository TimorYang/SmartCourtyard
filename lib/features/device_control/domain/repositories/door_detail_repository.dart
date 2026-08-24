import '../entities/door_detail.dart';
import '../entities/door_device.dart';
import '../entities/about_device_info.dart';

abstract interface class DoorDetailRepository {
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  });

  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  });

  Future<AboutDeviceInfo> fetchAboutDeviceInfo({
    required String doorId,
    required String deviceId,
    required String requestId,
  });

  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  });
}
