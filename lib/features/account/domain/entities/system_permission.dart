enum SystemPermission { location, camera, microphone, storage, bluetooth }

enum SystemPermissionStatus { granted, denied, blocked }

class SystemPermissionState {
  const SystemPermissionState({required this.permission, required this.status});

  final SystemPermission permission;
  final SystemPermissionStatus status;

  bool get isGranted => status == SystemPermissionStatus.granted;
}
