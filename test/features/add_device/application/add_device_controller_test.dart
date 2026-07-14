import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/features/add_device/domain/entities/onboarded_force_door.dart';
import 'package:flinx/features/add_device/domain/entities/onboarding_device_key.dart';
import 'package:flinx/features/add_device/domain/repositories/add_device_onboarding_repository.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final device = BleDevice(
    requestId: 'scan-1',
    scanSessionId: 'session-1',
    id: 'connected-device',
    sn: 'SN-001',
    rssi: -40,
    seenAtMillis: 0,
  );

  test('disconnects connected BLE devices before a new scan', () async {
    final gateway = _DisconnectTrackingGateway();
    final container = _createContainer(gateway);
    addTearDown(container.dispose);
    final controller = container.read(addDeviceControllerProvider.notifier);

    expect(await controller.connectAndAuthenticate(device), isTrue);
    await Future<void>.delayed(Duration.zero);

    expect(await controller.disconnectConnectedBleDevices(), isTrue);
    expect(gateway.disconnectedDeviceIds, ['connected-device']);
    expect(
      container
          .read(addDeviceControllerProvider)
          .connectionStateFor('connected-device'),
      BleConnectionState.disconnected,
    );
  });

  test('reports disconnect failure without preventing the next scan', () async {
    final gateway = _DisconnectTrackingGateway(throwOnDisconnect: true);
    final container = _createContainer(gateway);
    addTearDown(container.dispose);
    final controller = container.read(addDeviceControllerProvider.notifier);

    expect(await controller.connectAndAuthenticate(device), isTrue);
    await Future<void>.delayed(Duration.zero);

    expect(await controller.disconnectConnectedBleDevices(), isFalse);
    await controller.startScan();

    expect(gateway.scanStarted, isTrue);
  });
}

ProviderContainer _createContainer(_DisconnectTrackingGateway gateway) {
  return ProviderContainer(
    overrides: [
      addDeviceHardwareGatewayProvider.overrideWithValue(gateway),
      addDeviceOnboardingRepositoryProvider.overrideWithValue(
        const _FakeAddDeviceOnboardingRepository(),
      ),
    ],
  );
}

class _DisconnectTrackingGateway extends MockHardwareGateway {
  _DisconnectTrackingGateway({this.throwOnDisconnect = false});

  final bool throwOnDisconnect;
  final List<String> disconnectedDeviceIds = <String>[];
  var scanStarted = false;

  @override
  Future<void> startBleScan({
    required String requestId,
    BleScanFilter filter = const BleScanFilter(),
  }) async {
    scanStarted = true;
  }

  @override
  Future<BleConnectionEvent> disconnectBleDevice({
    required String requestId,
    required String deviceId,
  }) async {
    disconnectedDeviceIds.add(deviceId);
    if (throwOnDisconnect) {
      throw StateError('disconnect failed');
    }
    return super.disconnectBleDevice(requestId: requestId, deviceId: deviceId);
  }
}

class _FakeAddDeviceOnboardingRepository
    implements AddDeviceOnboardingRepository {
  const _FakeAddDeviceOnboardingRepository();

  @override
  Future<OnboardedForceDoor> addForceDoor({
    required String sn,
    required String requestId,
  }) async {
    return OnboardedForceDoor(id: 1, sn: sn);
  }

  @override
  Future<OnboardingDeviceKey> fetchDeviceKey({
    required String sn,
    required String requestId,
  }) async {
    return OnboardingDeviceKey(
      sn: sn,
      aesKey: '0123456789abcdef0123456789abcdef',
      aesKeyVersion: 'test',
    );
  }
}
