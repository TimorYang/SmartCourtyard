import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hardware_gateway.dart';
import 'mock_hardware_gateway.dart';

final hardwareGatewayProvider = Provider<HardwareGateway>((ref) {
  return const MockHardwareGateway();
});
