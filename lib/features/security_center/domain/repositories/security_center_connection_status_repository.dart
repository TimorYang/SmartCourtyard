import '../entities/security_center_connection_status.dart';

abstract interface class SecurityCenterConnectionStatusRepository {
  Future<SecurityCenterConnectionStatus> fetchConnectionStatus({
    required String doorId,
    required String requestId,
  });
}
