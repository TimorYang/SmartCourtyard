import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform_bridge/hardware_gateway.dart';
import '../../../platform_bridge/providers.dart';
import 'add_device_controller.dart';

final addDeviceHardwareGatewayProvider = Provider<HardwareGateway>((ref) {
  return ref.watch(nativeHardwareGatewayProvider);
});

final addDeviceControllerProvider =
    NotifierProvider<AddDeviceController, AddDeviceState>(
      AddDeviceController.new,
    );
