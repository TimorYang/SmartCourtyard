import 'dart:typed_data';

import 'hardware_models.dart';

abstract interface class HardwareGateway {
  Stream<BleDevice> get bleScanResults;

  Stream<BleConnectionEvent> get bleConnectionEvents;

  Stream<BleNotification> get bleNotifications;

  Stream<NativeHardwareError> get nativeErrors;

  Future<PermissionSnapshot> getPermissionSnapshot();

  Future<PermissionSnapshot> requestPermissions({
    required List<PermissionKind> permissions,
  });

  Future<List<DeviceSummary>> readDevices();

  Future<void> startBleScan({
    required String requestId,
    BleScanFilter filter = const BleScanFilter(),
  });

  Future<void> stopBleScan({required String requestId});

  Future<BleConnectionEvent> connectBleDevice({
    required String requestId,
    required String deviceId,
  });

  Future<BleAuthenticationResult> authenticateBleDevice({
    required String requestId,
    required String deviceId,
    required String token,
  });

  Future<WifiScanResult> scanWifiNetworks({
    required String requestId,
    required String deviceId,
  });

  Future<WifiProvisionResult> configureWifi({
    required String requestId,
    required String deviceId,
    required String ssid,
    required String password,
  });

  Future<BleConnectionEvent> disconnectBleDevice({
    required String requestId,
    required String deviceId,
  });

  Future<BleServices> discoverServices({
    required String requestId,
    required String deviceId,
  });

  Future<BleReadResult> readCharacteristic({
    required String requestId,
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  });

  Future<BleWriteResult> writeCharacteristic({
    required String requestId,
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    BleWriteType writeType = BleWriteType.withResponse,
  });

  Future<BleWriteResult> setCharacteristicNotify({
    required String requestId,
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required bool enabled,
  });

  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  });
}
