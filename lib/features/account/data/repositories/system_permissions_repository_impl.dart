import '../../../../platform_bridge/hardware_gateway.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../domain/entities/system_permission.dart';
import '../../domain/repositories/system_permissions_repository.dart';

class SystemPermissionsRepositoryImpl implements SystemPermissionsRepository {
  const SystemPermissionsRepositoryImpl(this._gateway);

  final HardwareGateway _gateway;

  @override
  Future<List<SystemPermissionState>> readPermissions({
    required String requestId,
  }) async {
    final snapshot = await _gateway.getPermissionSnapshot(requestId: requestId);
    return _mapSnapshot(snapshot);
  }

  @override
  Future<List<SystemPermissionState>> requestPermission({
    required SystemPermission permission,
    required String requestId,
  }) async {
    final snapshot = await _gateway.requestPermissions(
      requestId: requestId,
      permissions: [_toHardwarePermission(permission)],
    );
    return _mapSnapshot(snapshot);
  }

  @override
  Future<void> openAppSettings({required String requestId}) {
    return _gateway.openAppSettings(requestId: requestId);
  }

  List<SystemPermissionState> _mapSnapshot(PermissionSnapshot snapshot) {
    return [
      SystemPermissionState(
        permission: SystemPermission.location,
        status: _toStatus(snapshot.locationStatus),
      ),
      SystemPermissionState(
        permission: SystemPermission.camera,
        status: _toStatus(snapshot.cameraStatus),
      ),
      SystemPermissionState(
        permission: SystemPermission.microphone,
        status: _toStatus(snapshot.microphoneStatus),
      ),
      SystemPermissionState(
        permission: SystemPermission.storage,
        status: _toStatus(snapshot.storageStatus),
      ),
      SystemPermissionState(
        permission: SystemPermission.bluetooth,
        status: _toStatus(snapshot.bluetoothStatus),
      ),
    ];
  }

  PermissionKind _toHardwarePermission(SystemPermission permission) {
    return switch (permission) {
      SystemPermission.location => PermissionKind.location,
      SystemPermission.camera => PermissionKind.camera,
      SystemPermission.microphone => PermissionKind.microphone,
      SystemPermission.storage => PermissionKind.storage,
      SystemPermission.bluetooth => PermissionKind.bluetooth,
    };
  }

  SystemPermissionStatus _toStatus(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted => SystemPermissionStatus.granted,
      PermissionStatus.denied => SystemPermissionStatus.denied,
      PermissionStatus.blocked => SystemPermissionStatus.blocked,
    };
  }
}
