import 'dart:typed_data';

import '../core/errors/app_error.dart';

enum DoorCommand { open, stop, close, partialOpen, lightOn, lightOff, pb }

enum RemotePairingAction { start, cancel }

enum RemotePairingStatus { success, failure, timeout, unknown }

enum RemoteOperationStatus { success, failure, unknown }

enum DoorState { open, opening, stopped, closing, closed, unknown }

enum DeviceOnlineState { online, offline, unknown }

enum BleConnectionState { disconnected, connecting, connected }

enum BleWriteType { withResponse, withoutResponse }

class BleAuthenticationResult {
  const BleAuthenticationResult({
    required this.requestId,
    required this.deviceId,
    required this.authenticated,
    this.bindingState,
    this.nativeCode,
  });

  final String requestId;
  final String deviceId;
  final bool authenticated;
  final int? bindingState;
  final String? nativeCode;
}

class WifiNetwork {
  const WifiNetwork({required this.ssid});

  final String ssid;
}

class WifiScanResult {
  const WifiScanResult({
    required this.requestId,
    required this.deviceId,
    required this.networks,
  });

  final String requestId;
  final String deviceId;
  final List<WifiNetwork> networks;
}

class WifiProvisionResult {
  const WifiProvisionResult({
    required this.requestId,
    required this.deviceId,
    required this.ssid,
    required this.success,
    this.nativeCode,
  });

  final String requestId;
  final String deviceId;
  final String ssid;
  final bool success;
  final String? nativeCode;
}

enum PermissionKind { bluetooth, camera, localNetwork, notification }

class PermissionSnapshot {
  const PermissionSnapshot({
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

class DeviceSummary {
  const DeviceSummary({
    required this.id,
    required this.name,
    required this.onlineState,
    required this.bleState,
    required this.doorState,
    required this.cycleCount,
    required this.remainingLifePercent,
    this.lastSeenAt,
  });

  final String id;
  final String name;
  final DeviceOnlineState onlineState;
  final BleConnectionState bleState;
  final DoorState doorState;
  final int cycleCount;
  final int remainingLifePercent;
  final DateTime? lastSeenAt;
}

class CommandResult {
  const CommandResult({
    required this.requestId,
    required this.deviceId,
    required this.command,
    required this.accepted,
  });

  final String requestId;
  final String deviceId;
  final DoorCommand command;
  final bool accepted;
}

class RemotePairingResult {
  const RemotePairingResult({
    required this.requestId,
    required this.deviceId,
    required this.action,
    required this.status,
    required this.reasonCode,
    this.nativeCode,
  });

  final String requestId;
  final String deviceId;
  final RemotePairingAction action;
  final RemotePairingStatus status;
  final int reasonCode;
  final String? nativeCode;

  bool get successful => status == RemotePairingStatus.success;
}

class RemoteControl {
  const RemoteControl({required this.name, required this.serialNumber});

  final String name;
  final int serialNumber;

  String get serialNumberLabel =>
      '0x${serialNumber.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

class RemoteControlListResult {
  const RemoteControlListResult({
    required this.requestId,
    required this.deviceId,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.hasMore,
    required this.remotes,
  });

  final String requestId;
  final String deviceId;
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final bool hasMore;
  final List<RemoteControl> remotes;
}

class RemoteOperationResult {
  const RemoteOperationResult({
    required this.requestId,
    required this.deviceId,
    required this.status,
    required this.reasonCode,
    this.nativeCode,
  });

  final String requestId;
  final String deviceId;
  final RemoteOperationStatus status;
  final int reasonCode;
  final String? nativeCode;

  bool get successful => status == RemoteOperationStatus.success;
}

class BleScanFilter {
  const BleScanFilter({
    this.serviceUuids = const [],
    this.namePrefix,
    this.exactName,
    this.allowDuplicates = false,
  });

  final List<String> serviceUuids;
  final String? namePrefix;
  final String? exactName;
  final bool allowDuplicates;
}

class BleDevice {
  BleDevice({
    required this.requestId,
    required this.scanSessionId,
    required this.id,
    required this.rssi,
    required this.seenAtMillis,
    this.name,
    this.advertisementServiceUuids = const [],
    Uint8List? manufacturerData,
  }) : manufacturerData = manufacturerData ?? Uint8List(0);

  final String requestId;
  final String scanSessionId;
  final String id;
  final String? name;
  final int rssi;
  final int seenAtMillis;
  final List<String> advertisementServiceUuids;
  final Uint8List manufacturerData;
}

class BleConnectionEvent {
  const BleConnectionEvent({
    required this.requestId,
    required this.deviceId,
    required this.state,
    this.nativeCode,
  });

  final String requestId;
  final String deviceId;
  final BleConnectionState state;
  final String? nativeCode;
}

class BleCharacteristic {
  const BleCharacteristic({
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

class BleService {
  const BleService({required this.serviceUuid, required this.characteristics});

  final String serviceUuid;
  final List<BleCharacteristic> characteristics;
}

class BleServices {
  const BleServices({
    required this.requestId,
    required this.deviceId,
    required this.services,
  });

  final String requestId;
  final String deviceId;
  final List<BleService> services;
}

class BleReadResult {
  const BleReadResult({
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

class BleWriteResult {
  const BleWriteResult({
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

class BleNotification {
  const BleNotification({
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

class NativeHardwareError {
  const NativeHardwareError({
    required this.code,
    required this.domainCode,
    this.message,
    this.requestId,
    this.deviceId,
    required this.retryable,
    required this.timestampMillis,
  });

  final String code;
  final AppErrorCode domainCode;
  final String? message;
  final String? requestId;
  final String? deviceId;
  final bool retryable;
  final int timestampMillis;

  AppError toAppError() {
    return AppError(
      code: domainCode,
      messageKey: 'hardware.$code',
      action: switch (domainCode) {
        AppErrorCode.permissionDenied => AppErrorAction.openSettings,
        AppErrorCode.bluetoothUnavailable ||
        AppErrorCode.bluetoothDisconnected => AppErrorAction.connectBluetooth,
        AppErrorCode.commandTimeout ||
        AppErrorCode.deviceBusy ||
        AppErrorCode.unknown => AppErrorAction.retry,
        _ => AppErrorAction.none,
      },
      nativeCode: code,
      requestId: requestId,
      deviceId: deviceId,
      retryable: retryable,
    );
  }
}
