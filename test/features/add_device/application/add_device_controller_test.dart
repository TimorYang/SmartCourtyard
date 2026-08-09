import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/logging/providers.dart';
import 'package:flinx/features/add_device/domain/entities/add_door_draft.dart';
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

  test(
    'passes the QR target serial number as an exact BLE name filter',
    () async {
      final gateway = _DisconnectTrackingGateway();
      final container = _createContainer(gateway);
      addTearDown(container.dispose);

      await container
          .read(addDeviceControllerProvider.notifier)
          .startScan(targetSn: 'opener_B8F86211A9DC');

      expect(gateway.lastScanFilter?.exactName, 'opener_B8F86211A9DC');
      expect(gateway.lastScanFilter?.namePrefix, isNull);
    },
  );

  test('stores the pending door draft for the onboarding flow', () {
    final container = _createContainer(_DisconnectTrackingGateway());
    addTearDown(container.dispose);
    const draft = AddDoorDraft(
      name: 'Garage door',
      sceneId: 2,
      sceneName: 'Warehouse',
    );

    container
        .read(addDeviceControllerProvider.notifier)
        .setPendingDoorDraft(draft);

    expect(container.read(addDeviceControllerProvider).pendingDoorDraft, draft);
  });

  test(
    'uses one flow id across scan, authentication, provisioning and binding',
    () async {
      final gateway = _FlowTrackingGateway();
      final logger = _RecordingLogger();
      final container = ProviderContainer(
        overrides: [
          addDeviceHardwareGatewayProvider.overrideWithValue(gateway),
          addDeviceOnboardingRepositoryProvider.overrideWithValue(
            const _FakeAddDeviceOnboardingRepository(),
          ),
          appLoggerProvider.overrideWithValue(logger),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(addDeviceControllerProvider.notifier);
      controller.beginOnboardingFlow(
        doorId: '1',
        sceneId: 12,
        doorType: DoorType.industrial,
      );

      await controller.startScan();
      expect(await controller.connectAndAuthenticate(device), isTrue);
      controller.updateWifiSsid('test-network');
      controller.updateWifiPassword('never-log-this');
      expect(await controller.configureWifi(), isTrue);

      final flowId = container
          .read(addDeviceControllerProvider)
          .onboardingFlowId;
      expect(flowId, isNotNull);
      expect(gateway.requestIds, everyElement(startsWith('$flowId:')));
      expect(
        logger.events,
        containsAllInOrder([
          'onboarding_flow_started',
          'ble_scan_started',
          'ble_connect_started',
          'device_key_fetch_started',
          'ble_authentication_started',
          'wifi_provision_started',
          'cloud_binding_started',
          'cloud_binding_completed',
        ]),
      );
      expect(logger.tags, everyElement(AppLogTag.binding));
      expect(_FakeAddDeviceOnboardingRepository.lastDoorTypeWireValue, 2);
      expect(_FakeAddDeviceOnboardingRepository.lastSceneId, 12);
    },
  );
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
  BleScanFilter? lastScanFilter;

  @override
  Future<void> startBleScan({
    required String requestId,
    BleScanFilter filter = const BleScanFilter(),
  }) async {
    scanStarted = true;
    lastScanFilter = filter;
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

class _FlowTrackingGateway extends MockHardwareGateway {
  final List<String> requestIds = <String>[];

  @override
  Future<void> startBleScan({
    required String requestId,
    BleScanFilter filter = const BleScanFilter(),
  }) async {
    requestIds.add(requestId);
  }

  @override
  Future<BleConnectionEvent> connectBleDevice({
    required String requestId,
    required String deviceId,
  }) {
    requestIds.add(requestId);
    return super.connectBleDevice(requestId: requestId, deviceId: deviceId);
  }

  @override
  Future<BleAuthenticationResult> authenticateBleDevice({
    required String requestId,
    required String deviceId,
    required String token,
    required String aesKey,
    required String aesKeyVersion,
  }) {
    requestIds.add(requestId);
    return super.authenticateBleDevice(
      requestId: requestId,
      deviceId: deviceId,
      token: token,
      aesKey: aesKey,
      aesKeyVersion: aesKeyVersion,
    );
  }

  @override
  Future<WifiProvisionResult> configureWifi({
    required String requestId,
    required String deviceId,
    required String ssid,
    required String password,
  }) {
    requestIds.add(requestId);
    return super.configureWifi(
      requestId: requestId,
      deviceId: deviceId,
      ssid: ssid,
      password: password,
    );
  }
}

class _RecordingLogger implements AppLogger {
  final List<String> events = <String>[];
  final List<AppLogTag> tags = <AppLogTag>[];

  void _record(String message, AppLogTag tag) {
    events.add(message);
    tags.add(tag);
  }

  @override
  void info(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) => _record(message, tag);

  @override
  void warning(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) => _record(message, tag);

  @override
  void error(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) => _record(message, tag);
}

class _FakeAddDeviceOnboardingRepository
    implements AddDeviceOnboardingRepository {
  const _FakeAddDeviceOnboardingRepository();

  static int? lastDoorTypeWireValue;
  static int? lastSceneId;

  @override
  Future<void> validateBindingStatus({
    required String sn,
    required String requestId,
  }) async {}

  @override
  Future<OnboardedForceDoor> addForceDoor({
    required String sn,
    String? doorId,
    int? sceneId,
    required int doorType,
    required String requestId,
  }) async {
    lastDoorTypeWireValue = doorType;
    lastSceneId = sceneId;
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
