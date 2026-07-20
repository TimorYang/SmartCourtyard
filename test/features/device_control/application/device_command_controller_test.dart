import 'dart:async';

import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/features/add_device/domain/entities/onboarded_force_door.dart';
import 'package:flinx/features/add_device/domain/entities/onboarding_device_key.dart';
import 'package:flinx/features/add_device/domain/repositories/add_device_onboarding_repository.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/domain/entities/door_detail.dart';
import 'package:flinx/features/device_control/domain/repositories/door_detail_repository.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'connects and authenticates the BLE device matching hardwareSn',
    () async {
      final gateway = _BleSessionGateway();
      final container = _createContainer(gateway: gateway);
      addTearDown(container.dispose);

      await container
          .read(deviceCommandControllerProvider.notifier)
          .loadDoorDetail(doorId: '12');
      await _settleBleSession();

      expect(gateway.exactScanNames, ['SN-001']);
      expect(gateway.connectedDeviceIds, ['target-device']);
      expect(gateway.authenticatedDeviceIds, ['target-device']);
      final state = container.read(deviceCommandControllerProvider);
      expect(state.bleConnectionStatus, DeviceBleConnectionStatus.connected);
      expect(state.bleDeviceId, 'target-device');
    },
  );

  test(
    'does not start BLE discovery when the detail has no hardwareSn',
    () async {
      final gateway = _BleSessionGateway();
      final container = _createContainer(
        gateway: gateway,
        doorDetail: _doorDetail(hardwareSn: null),
      );
      addTearDown(container.dispose);

      await container
          .read(deviceCommandControllerProvider.notifier)
          .loadDoorDetail(doorId: '12');
      await _settleBleSession();

      expect(gateway.exactScanNames, isEmpty);
    },
  );

  test('disconnects and returns to idle when authentication fails', () async {
    final gateway = _BleSessionGateway(authenticationSucceeds: false);
    final container = _createContainer(gateway: gateway);
    addTearDown(container.dispose);

    await container
        .read(deviceCommandControllerProvider.notifier)
        .loadDoorDetail(doorId: '12');
    await _settleBleSession();

    expect(
      container.read(deviceCommandControllerProvider).bleConnectionStatus,
      DeviceBleConnectionStatus.idle,
    );
    expect(gateway.disconnectedDeviceIds, ['target-device']);
  });

  test('stops scanning and returns to idle after the scan timeout', () async {
    final gateway = _BleSessionGateway(emitTargetDevice: false);
    final container = _createContainer(
      gateway: gateway,
      scanDuration: Duration.zero,
    );
    addTearDown(container.dispose);

    await container
        .read(deviceCommandControllerProvider.notifier)
        .loadDoorDetail(doorId: '12');
    await _settleBleSession();

    expect(gateway.stopScanCount, greaterThanOrEqualTo(2));
    expect(
      container.read(deviceCommandControllerProvider).bleConnectionStatus,
      DeviceBleConnectionStatus.idle,
    );
  });
}

ProviderContainer _createContainer({
  required _BleSessionGateway gateway,
  DoorDetail? doorDetail,
  Duration scanDuration = const Duration(seconds: 10),
}) {
  return ProviderContainer(
    overrides: [
      deviceCommandHardwareGatewayProvider.overrideWithValue(gateway),
      doorDetailRepositoryProvider.overrideWithValue(
        _DoorDetailRepository(doorDetail ?? _doorDetail()),
      ),
      addDeviceOnboardingRepositoryProvider.overrideWithValue(
        const _DeviceKeyRepository(),
      ),
      deviceCommandBleScanDurationProvider.overrideWithValue(scanDuration),
    ],
  );
}

Future<void> _settleBleSession() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

DoorDetail _doorDetail({String? hardwareSn = 'SN-001'}) {
  return DoorDetail(
    id: '12',
    name: 'Test door',
    doorState: DoorState.closed,
    doorStateLabel: 'Closed',
    operatedCycles: 0,
    remainingCycles: 0,
    hardwareSn: hardwareSn,
  );
}

class _DoorDetailRepository implements DoorDetailRepository {
  const _DoorDetailRepository(this.detail);

  final DoorDetail detail;

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) async => detail;
}

class _DeviceKeyRepository implements AddDeviceOnboardingRepository {
  const _DeviceKeyRepository();

  @override
  Future<OnboardedForceDoor> addForceDoor({
    required String sn,
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<OnboardingDeviceKey> fetchDeviceKey({
    required String sn,
    required String requestId,
  }) async => OnboardingDeviceKey(
    sn: sn,
    aesKey: '0123456789abcdef0123456789abcdef',
    aesKeyVersion: 'test',
  );
}

class _BleSessionGateway extends MockHardwareGateway {
  _BleSessionGateway({
    this.emitTargetDevice = true,
    this.authenticationSucceeds = true,
  });

  final bool emitTargetDevice;
  final bool authenticationSucceeds;
  final StreamController<BleDevice> _scanResults =
      StreamController<BleDevice>.broadcast();
  final List<String> exactScanNames = <String>[];
  final List<String> connectedDeviceIds = <String>[];
  final List<String> authenticatedDeviceIds = <String>[];
  final List<String> disconnectedDeviceIds = <String>[];
  var stopScanCount = 0;

  @override
  Stream<BleDevice> get bleScanResults => _scanResults.stream;

  @override
  Future<void> startBleScan({
    required String requestId,
    BleScanFilter filter = const BleScanFilter(),
  }) async {
    exactScanNames.add(filter.exactName ?? '');
    _scanResults.add(
      BleDevice(
        requestId: requestId,
        scanSessionId: 'session',
        id: 'other-device',
        name: 'other-name',
        sn: 'other-name',
        rssi: -60,
        seenAtMillis: 0,
      ),
    );
    if (emitTargetDevice) {
      _scanResults.add(
        BleDevice(
          requestId: requestId,
          scanSessionId: 'session',
          id: 'target-device',
          name: filter.exactName,
          sn: filter.exactName,
          rssi: -40,
          seenAtMillis: 0,
        ),
      );
    }
  }

  @override
  Future<void> stopBleScan({required String requestId}) async {
    stopScanCount += 1;
  }

  @override
  Future<BleConnectionEvent> connectBleDevice({
    required String requestId,
    required String deviceId,
  }) async {
    connectedDeviceIds.add(deviceId);
    return BleConnectionEvent(
      requestId: requestId,
      deviceId: deviceId,
      state: BleConnectionState.connected,
    );
  }

  @override
  Future<BleAuthenticationResult> authenticateBleDevice({
    required String requestId,
    required String deviceId,
    required String token,
    required String aesKey,
  }) async {
    authenticatedDeviceIds.add(deviceId);
    return BleAuthenticationResult(
      requestId: requestId,
      deviceId: deviceId,
      authenticated: authenticationSucceeds,
      bindingState: authenticationSucceeds ? 0xF1 : 0,
    );
  }

  @override
  Future<BleConnectionEvent> disconnectBleDevice({
    required String requestId,
    required String deviceId,
  }) async {
    disconnectedDeviceIds.add(deviceId);
    return BleConnectionEvent(
      requestId: requestId,
      deviceId: deviceId,
      state: BleConnectionState.disconnected,
    );
  }
}
