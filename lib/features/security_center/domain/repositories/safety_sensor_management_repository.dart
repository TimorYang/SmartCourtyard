import '../entities/safety_sensor_management.dart';

abstract interface class SafetySensorManagementRepository {
  Future<SafetySensorManagement> query({
    required String requestId,
    required String deviceId,
  });

  Future<void> delete({
    required String requestId,
    required String deviceId,
    required int serialNumber,
  });
}
