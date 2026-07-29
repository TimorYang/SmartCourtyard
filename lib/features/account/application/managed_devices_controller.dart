import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/managed_login_device.dart';
import '../domain/use_cases/fetch_managed_login_devices_use_case.dart';
import '../domain/use_cases/remove_managed_login_device_use_case.dart';
import 'providers.dart';

final managedDevicesControllerProvider =
    AsyncNotifierProvider<ManagedDevicesController, List<ManagedLoginDevice>>(
      ManagedDevicesController.new,
    );

class ManagedDevicesController extends AsyncNotifier<List<ManagedLoginDevice>> {
  FetchManagedLoginDevicesUseCase get _fetchDevices =>
      ref.read(fetchManagedLoginDevicesUseCaseProvider);
  RemoveManagedLoginDeviceUseCase get _removeDevice =>
      ref.read(removeManagedLoginDeviceUseCaseProvider);

  @override
  Future<List<ManagedLoginDevice>> build() async => const [];

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> removeDevice(String sessionId) async {
    await _removeDevice(
      sessionId: sessionId,
      requestId:
          'remove-login-device-$sessionId-${DateTime.now().toUtc().microsecondsSinceEpoch}',
    );
    final devices = state.asData?.value ?? const <ManagedLoginDevice>[];
    state = AsyncData(
      devices
          .where((device) => device.sessionId != sessionId)
          .toList(growable: false),
    );
  }

  Future<List<ManagedLoginDevice>> _load() => _fetchDevices(
    requestId:
        'managed-login-devices-${DateTime.now().toUtc().microsecondsSinceEpoch}',
  );
}
