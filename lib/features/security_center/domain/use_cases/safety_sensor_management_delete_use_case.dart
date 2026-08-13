import '../repositories/safety_sensor_management_repository.dart';

class SafetySensorManagementDeleteUseCase {
  const SafetySensorManagementDeleteUseCase({required this.repository});

  final SafetySensorManagementRepository repository;

  Future<void> call({
    required String requestId,
    required String deviceId,
    required int serialNumber,
  }) => repository.delete(
    requestId: requestId,
    deviceId: deviceId,
    serialNumber: serialNumber,
  );
}
