import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform_bridge/hardware_models.dart';
import '../../../platform_bridge/providers.dart';

final homeDevicesProvider = FutureProvider<List<DeviceSummary>>((ref) {
  final hardwareGateway = ref.watch(hardwareGatewayProvider);

  return hardwareGateway.readDevices();
});
