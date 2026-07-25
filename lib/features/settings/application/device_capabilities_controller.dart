import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/device_capability.dart';
import '../domain/use_cases/fetch_device_capabilities_use_case.dart';
import 'providers.dart';

final deviceCapabilitiesControllerProvider =
    NotifierProvider.family<
      DeviceCapabilitiesController,
      DeviceCapabilitiesState,
      String
    >((deviceId) => DeviceCapabilitiesController(deviceId));

class DeviceCapabilitiesState {
  const DeviceCapabilitiesState({
    this.capabilities = const <DeviceCapability>[],
    this.loading = true,
    this.errorMessage,
  });

  final List<DeviceCapability> capabilities;
  final bool loading;
  final String? errorMessage;

  bool supports(String code) =>
      capabilities.any((capability) => capability.code.toUpperCase() == code);

  DeviceCapability? capabilityFor(String code) {
    for (final capability in capabilities) {
      if (capability.code.toUpperCase() == code) {
        return capability;
      }
    }
    return null;
  }
}

class DeviceCapabilitiesController extends Notifier<DeviceCapabilitiesState> {
  DeviceCapabilitiesController(this.deviceId);

  final String deviceId;
  late final FetchDeviceCapabilitiesUseCase _fetchCapabilities;
  int _requestCounter = 0;

  @override
  DeviceCapabilitiesState build() {
    _fetchCapabilities = ref.watch(fetchDeviceCapabilitiesUseCaseProvider);
    Future.microtask(load);
    return const DeviceCapabilitiesState();
  }

  Future<void> load() async {
    if (!ref.mounted) {
      return;
    }
    state = DeviceCapabilitiesState(
      capabilities: state.capabilities,
      loading: true,
    );
    try {
      final capabilities = await _fetchCapabilities(
        deviceId: deviceId,
        requestId: _nextRequestId(),
      );
      if (!ref.mounted) {
        return;
      }
      state = DeviceCapabilitiesState(
        capabilities: List<DeviceCapability>.unmodifiable(capabilities),
        loading: false,
      );
    } catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = DeviceCapabilitiesState(
        capabilities: state.capabilities,
        loading: false,
        errorMessage: error.toString(),
      );
    }
  }

  String _nextRequestId() {
    _requestCounter++;
    return 'device-capabilities-${DateTime.now().microsecondsSinceEpoch}-$_requestCounter';
  }
}
