import '../entities/system_permission.dart';
import '../repositories/system_permissions_repository.dart';

class ReadSystemPermissionsUseCase {
  const ReadSystemPermissionsUseCase(this._repository);

  final SystemPermissionsRepository _repository;

  Future<List<SystemPermissionState>> call({required String requestId}) {
    return _repository.readPermissions(requestId: requestId);
  }
}
