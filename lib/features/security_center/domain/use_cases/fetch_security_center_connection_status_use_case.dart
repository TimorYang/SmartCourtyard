import '../entities/security_center_connection_status.dart';
import '../repositories/security_center_connection_status_repository.dart';

class FetchSecurityCenterConnectionStatusUseCase {
  const FetchSecurityCenterConnectionStatusUseCase({required this.repository});

  final SecurityCenterConnectionStatusRepository repository;

  Future<SecurityCenterConnectionStatus> call({
    required String doorId,
    required String requestId,
  }) => repository.fetchConnectionStatus(doorId: doorId, requestId: requestId);
}
