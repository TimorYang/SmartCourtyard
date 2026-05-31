import 'dart:typed_data';

enum DoorCommand { open, stop, close }

enum DoorState { open, opening, stopped, closing, closed, unknown }

enum DeviceOnlineState { online, offline, unknown }

enum BleConnectionState { disconnected, connecting, connected }

enum BleWriteType { withResponse, withoutResponse }

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
    required this.id,
    required this.rssi,
    this.name,
    this.advertisementServiceUuids = const [],
    Uint8List? manufacturerData,
  }) : manufacturerData = manufacturerData ?? Uint8List(0);

  final String id;
  final String? name;
  final int rssi;
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
    required this.deviceId,
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.payload,
  });

  final String deviceId;
  final String serviceUuid;
  final String characteristicUuid;
  final Uint8List payload;
}

class NativeHardwareError {
  const NativeHardwareError({
    required this.code,
    this.message,
    this.requestId,
    this.deviceId,
  });

  final String code;
  final String? message;
  final String? requestId;
  final String? deviceId;
}
