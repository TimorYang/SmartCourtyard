enum DoorCommand { open, stop, close }

enum DoorState { open, opening, stopped, closing, closed, unknown }

enum DeviceOnlineState { online, offline, unknown }

enum BleConnectionState { disconnected, connecting, connected }

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
