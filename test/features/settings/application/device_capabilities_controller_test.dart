import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flinx/features/settings/application/device_capabilities_controller.dart';
import 'package:flinx/features/settings/application/providers.dart';
import 'package:flinx/features/settings/domain/entities/device_capability.dart';
import 'package:flinx/features/settings/domain/repositories/device_capability_repository.dart';

void main() {
  test('refetches capabilities after the last listener is removed', () async {
    final repository = _CountingDeviceCapabilityRepository();
    final container = ProviderContainer(
      overrides: [
        deviceCapabilityRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final provider = deviceCapabilitiesControllerProvider('device-1');
    final firstSubscription = container.listen(provider, (_, _) {});
    addTearDown(firstSubscription.close);

    await _waitUntil(() => !container.read(provider).loading);
    expect(repository.fetchCount, 1);

    firstSubscription.close();
    await Future<void>.delayed(Duration.zero);

    final secondSubscription = container.listen(provider, (_, _) {});
    addTearDown(secondSubscription.close);

    await _waitUntil(() => !container.read(provider).loading);
    expect(repository.fetchCount, 2);
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100 && !condition(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(condition(), isTrue);
}

class _CountingDeviceCapabilityRepository
    implements DeviceCapabilityRepository {
  var fetchCount = 0;

  @override
  Future<List<DeviceCapability>> fetchCapabilities({
    required String deviceId,
    required String requestId,
  }) async {
    fetchCount++;
    return const <DeviceCapability>[];
  }
}
