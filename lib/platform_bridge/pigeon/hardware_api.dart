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

enum BleConnectionStateDto { disconnected, connecting, connected }

enum BleWriteTypeDto { withResponse, withoutResponse }

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

class BleScanFilterDto {
  BleScanFilterDto({
    required this.serviceUuids,
    this.namePrefix,
    this.exactName,
    required this.allowDuplicates,
  });

  final List<String> serviceUuids;
  final String? namePrefix;
  final String? exactName;
  final bool allowDuplicates;
}

class BleDeviceDto {
  BleDeviceDto({
    required this.requestId,
    required this.scanSessionId,
    required this.id,
    this.name,
    required this.rssi,
    required this.advertisementServiceUuids,
    required this.manufacturerData,
    required this.seenAtMillis,
  });

  final String requestId;
  final String scanSessionId;
  final String id;
  final String? name;
  final int rssi;
  final List<String> advertisementServiceUuids;
  final Uint8List manufacturerData;
  final int seenAtMillis;
}

class BleConnectionEventDto {
  BleConnectionEventDto({
    required this.requestId,
    required this.deviceId,
    required this.state,
    this.nativeCode,
  });

  final String requestId;
  final String deviceId;
  final BleConnectionStateDto state;
  final String? nativeCode;
}

class BleCharacteristicDto {
  BleCharacteristicDto({
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.canRead,
    required this.canWriteWithResponse,
    required this.canWriteWithoutResponse,
    required this.canNotify,
  });

  final String serviceUuid;
  final String characteristicUuid;
  final bool canRead;
  final bool canWriteWithResponse;
  final bool canWriteWithoutResponse;
  final bool canNotify;
}

class BleServiceDto {
  BleServiceDto({required this.serviceUuid, required this.characteristics});

  final String serviceUuid;
  final List<BleCharacteristicDto> characteristics;
}

class BleServicesDto {
  BleServicesDto({
    required this.requestId,
    required this.deviceId,
    required this.services,
  });

  final String requestId;
  final String deviceId;
  final List<BleServiceDto> services;
}

class BleReadResultDto {
  BleReadResultDto({
    required this.requestId,
    required this.deviceId,
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.payload,
  });

  final String requestId;
  final String deviceId;
  final String serviceUuid;
  final String characteristicUuid;
  final Uint8List payload;
}

class BleWriteResultDto {
  BleWriteResultDto({
    required this.requestId,
    required this.deviceId,
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.accepted,
    this.nativeCode,
  });

  final String requestId;
  final String deviceId;
  final String serviceUuid;
  final String characteristicUuid;
  final bool accepted;
  final String? nativeCode;
}

class BleNotificationDto {
  BleNotificationDto({
    this.requestId,
    required this.deviceId,
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.payload,
    required this.timestampMillis,
    required this.sequenceNumber,
  });

  final String? requestId;
  final String deviceId;
  final String serviceUuid;
  final String characteristicUuid;
  final Uint8List payload;
  final int timestampMillis;
  final int sequenceNumber;
}

class NativeErrorDto {
  NativeErrorDto({
    required this.code,
    required this.domainCode,
    this.message,
    this.requestId,
    this.deviceId,
    required this.retryable,
    required this.timestampMillis,
  });

  final String code;
  final String domainCode;
  final String? message;
  final String? requestId;
  final String? deviceId;
  final bool retryable;
  final int timestampMillis;
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

  void startBleScan(String requestId, BleScanFilterDto filter);

  void stopBleScan(String requestId);

  @async
  BleConnectionEventDto connectBleDevice(String requestId, String deviceId);

  @async
  BleConnectionEventDto disconnectBleDevice(String requestId, String deviceId);

  @async
  BleServicesDto discoverServices(String requestId, String deviceId);

  @async
  BleReadResultDto readCharacteristic(
    String requestId,
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  );

  @async
  BleWriteResultDto writeCharacteristic(
    String requestId,
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
    Uint8List payload,
    BleWriteTypeDto writeType,
  );

  @async
  BleWriteResultDto setCharacteristicNotify(
    String requestId,
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
    bool enabled,
  );

  CommandResultDto sendDoorCommand(
    String requestId,
    String deviceId,
    DoorCommandDto command,
  );
}

@FlutterApi()
abstract class HardwareFlutterApi {
  void onBleScanResult(BleDeviceDto device);

  void onBleConnectionChanged(BleConnectionEventDto event);

  void onBleNotification(BleNotificationDto notification);

  void onNativeError(NativeErrorDto error);
}
