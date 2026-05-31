import 'hardware_gateway.dart';
import 'hardware_models.dart';

class MockHardwareGateway implements HardwareGateway {
  const MockHardwareGateway();

  @override
  Future<List<DeviceSummary>> readDevices() async {
    return [
      DeviceSummary(
        id: 'mock-garage-door',
        name: 'Garage Door',
        onlineState: DeviceOnlineState.online,
        bleState: BleConnectionState.connected,
        doorState: DoorState.closed,
        cycleCount: 328,
        remainingLifePercent: 91,
        lastSeenAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  }) async {
    return CommandResult(
      requestId: requestId,
      deviceId: deviceId,
      command: command,
      accepted: true,
    );
  }
}
