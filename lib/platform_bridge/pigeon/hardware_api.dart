import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'flinx',
    dartOut: 'lib/platform_bridge/pigeon/generated/hardware_api.g.dart',
    swiftOut: 'ios/Runner/FLINXHardware/Bridge/HardwareApi.g.swift',
    kotlinOut:
        'android/app/src/main/kotlin/com/flinx/flinx/flinxhardware/bridge/HardwareApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.flinx.flinx.flinxhardware.bridge',
    ),
  ),
)
enum PermissionKindDto { bluetooth, camera, localNetwork, notification }

enum DoorCommandDto { open, stop, close }

class PermissionSnapshotDto {
  PermissionSnapshotDto({
    required this.bluetoothGranted,
    required this.cameraGranted,
    required this.localNetworkGranted,
    required this.notificationGranted,
  });

  final bool bluetoothGranted;
  final bool cameraGranted;
  final bool localNetworkGranted;
  final bool notificationGranted;
}

class CommandResultDto {
  CommandResultDto({
    required this.requestId,
    required this.deviceId,
    required this.accepted,
    this.nativeCode,
    this.domainCode,
  });

  final String requestId;
  final String deviceId;
  final bool accepted;
  final String? nativeCode;
  final String? domainCode;
}

@HostApi()
abstract class HardwareHostApi {
  PermissionSnapshotDto getPermissionSnapshot();

  PermissionSnapshotDto requestPermissions(List<PermissionKindDto> permissions);

  CommandResultDto sendDoorCommand(
    String requestId,
    String deviceId,
    DoorCommandDto command,
  );
}
