import '../entities/safety_sensor_management.dart';
import '../repositories/safety_sensor_management_repository.dart';

class SafetySensorManagementQueryUseCase {
  const SafetySensorManagementQueryUseCase({required this.repository});

  final SafetySensorManagementRepository repository;

  Future<SafetySensorManagement> call({
    required String requestId,
    required String deviceId,
  }) => repository.query(requestId: requestId, deviceId: deviceId);
}
