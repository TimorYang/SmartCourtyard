import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform_bridge/hardware_gateway.dart';
import '../../../platform_bridge/hardware_models.dart';
import '../../../platform_bridge/providers.dart';

final deviceCommandHardwareGatewayProvider = Provider<HardwareGateway>((ref) {
  return ref.watch(nativeHardwareGatewayProvider);
});

final localDoorCommandExecutorProvider = Provider<LocalDoorCommandExecutor>(
  (ref) => LocalDoorCommandExecutor(
    gateway: ref.watch(deviceCommandHardwareGatewayProvider),
  ),
);

class LocalDoorCommandExecutor {
  const LocalDoorCommandExecutor({required this.gateway});

  final HardwareGateway gateway;

  Future<CommandResult> send({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  }) {
    return gateway.sendDoorCommand(
      requestId: requestId,
      deviceId: deviceId,
      command: command,
    );
  }
}
