import '../entities/system_permission.dart';
import '../repositories/system_permissions_repository.dart';

class RequestSystemPermissionUseCase {
  const RequestSystemPermissionUseCase(this._repository);

  final SystemPermissionsRepository _repository;

  Future<List<SystemPermissionState>> call({
    required SystemPermission permission,
    required String requestId,
  }) {
    return _repository.requestPermission(
      permission: permission,
      requestId: requestId,
    );
  }
}
