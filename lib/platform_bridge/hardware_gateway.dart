import 'dart:typed_data';

import 'hardware_models.dart';

abstract interface class HardwareGateway {
  Stream<BleDevice> get bleScanResults;

  Stream<BleConnectionEvent> get bleConnectionEvents;

  Stream<BleNotification> get bleNotifications;

  Stream<NativeHardwareError> get nativeErrors;

  Stream<BleDiagnosticEvent> get bleDiagnosticEvents;

  Stream<DeviceAttributeSnapshot> get deviceAttributeSnapshots;

  Future<void> configureHardwareLogging({
    required bool flutterConsoleEnabled,
    required bool nativeConsoleEnabled,
  });

  Future<PermissionSnapshot> getPermissionSnapshot({required String requestId});

  Future<PermissionSnapshot> requestPermissions({
    required String requestId,
    required List<PermissionKind> permissions,
  });

  Future<void> openAppSettings({required String requestId});

  Future<List<DeviceSummary>> readDevices();

  Future<void> startBleScan({
    required String requestId,
    BleScanFilter filter = const BleScanFilter(),
  });

  Future<void> stopBleScan({required String requestId});

  Future<List<ConnectedBleDevice>> getConnectedBleDevices({
    required String requestId,
  });

  Future<List<BleConnectionEvent>> disconnectAllManagedBleDevices({
    required String requestId,
  });

  Future<BleConnectionEvent> connectBleDevice({
    required String requestId,
    required String deviceId,
  });

  Future<BleAuthenticationResult> authenticateBleDevice({
    required String requestId,
    required String deviceId,
    required String token,
    required String aesKey,
    required String aesKeyVersion,
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

  Future<DeviceAttributeSnapshot> queryDeviceAttributes({
    required String requestId,
    required String deviceId,
  });

  Future<DeviceAttributeWriteResult> setDeviceAttributes({
    required String requestId,
    required String deviceId,
    required List<DeviceAttribute> attributes,
  });

  Future<RemotePairingResult> pairRemote({
    required String requestId,
    required String deviceId,
    required RemotePairingAction action,
  });

  Future<SafetyAccessoryPairingResult> pairSafetyAccessory({
    required String requestId,
    required String deviceId,
    required SafetyAccessoryPairingAction action,
  });

  Future<SafetyAccessoryListResult> querySafetyAccessories({
    required String requestId,
    required String deviceId,
  });

  Future<SafetyAccessoryDeleteResult> deleteSafetyAccessory({
    required String requestId,
    required String deviceId,
    required int serialNumber,
  });

  Future<RemoteControlListResult> queryRemotes({
    required String requestId,
    required String deviceId,
  });

  Future<RemoteOperationResult> deleteRemote({
    required String requestId,
    required String deviceId,
    int? serialNumber,
  });

  Future<RemoteOperationResult> renameRemote({
    required String requestId,
    required String deviceId,
    required int serialNumber,
    required String name,
  });
}
