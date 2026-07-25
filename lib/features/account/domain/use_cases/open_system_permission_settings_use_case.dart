import '../repositories/system_permissions_repository.dart';

class OpenSystemPermissionSettingsUseCase {
  const OpenSystemPermissionSettingsUseCase(this._repository);

  final SystemPermissionsRepository _repository;

  Future<void> call({required String requestId}) {
    return _repository.openAppSettings(requestId: requestId);
  }
}
