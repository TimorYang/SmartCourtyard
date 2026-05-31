import 'hardware_models.dart';

abstract interface class HardwareGateway {
  Future<List<DeviceSummary>> readDevices();

  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  });
}
