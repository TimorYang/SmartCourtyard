import '../entities/system_permission.dart';

abstract interface class SystemPermissionsRepository {
  Future<List<SystemPermissionState>> readPermissions({
    required String requestId,
  });

  Future<List<SystemPermissionState>> requestPermission({
    required SystemPermission permission,
    required String requestId,
  });

  Future<void> openAppSettings({required String requestId});
}
