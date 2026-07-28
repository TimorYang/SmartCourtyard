import 'dart:async';
import 'dart:typed_data';

import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/logging/providers.dart';
import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/features/add_device/domain/entities/onboarded_force_door.dart';
import 'package:flinx/features/add_device/domain/entities/onboarding_device_key.dart';
import 'package:flinx/features/add_device/domain/repositories/add_device_onboarding_repository.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/domain/entities/door_detail.dart';
import 'package:flinx/features/device_control/domain/entities/door_device.dart';
import 'package:flinx/features/device_control/domain/repositories/door_detail_repository.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'connects and authenticates the BLE device named by the door detail',
    () async {
      final gateway = _BleSessionGateway();
      final container = _createContainer(gateway: gateway);
      addTearDown(container.dispose);

      await container
          .read(deviceCommandControllerProvider.notifier)
          .loadDoorDetail(doorId: '12');
      await _settleBleSession();

      expect(gateway.exactScanNames, ['']);
      expect(gateway.connectedDeviceIds, ['target-device']);
      expect(gateway.authenticatedDeviceIds, ['target-device']);
      final state = container.read(deviceCommandControllerProvider);
      expect(state.bleConnectionStatus, DeviceBleConnectionStatus.connected);
      expect(state.bleDeviceId, 'target-device');
    },
  );

  test(
    'does not start BLE discovery when the detail has no BLE name',
    () async {
      final gateway = _BleSessionGateway();
      final container = _createContainer(
        gateway: gateway,
        doorDetail: _doorDetail(name: ''),
        repository: _DoorDetailRepository(
          _doorDetail(name: ''),
          devices: const <DoorDevice>[],
        ),
      );
      addTearDown(container.dispose);

      await container
          .read(deviceCommandControllerProvider.notifier)
          .loadDoorDetail(doorId: '12');
      await _settleBleSession();

      expect(gateway.exactScanNames, isEmpty);
    },
  );

  test(
    'tapping a device only changes selection without reconnecting',
    () async {
      final gateway = _BleSessionGateway();
      final container = _createContainer(gateway: gateway);
      addTearDown(container.dispose);
      final controller = container.read(
        deviceCommandControllerProvider.notifier,
      );

      await controller.loadDoorDetail(doorId: '12');
      await _settleBleSession();
      await controller.connectDoorDevice(bleName: 'Test door');
      await _settleBleSession();

      expect(gateway.exactScanNames, ['']);
      expect(gateway.connectedDeviceIds, ['target-device']);
      final state = container.read(deviceCommandControllerProvider);
      expect(state.bleConnectionStatus, DeviceBleConnectionStatus.connected);
      expect(state.bleTargetName, 'Test door');
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

  test(
    'refreshes door devices when an already-added device is removed',
    () async {
      final gateway = _BleSessionGateway();
      final repository = _DoorDetailRepository(
        _doorDetail(),
        devices: const [
          DoorDevice(deviceId: '3', sn: 'old', deviceType: 'opener'),
        ],
      );
      final container = _createContainer(
        gateway: gateway,
        repository: repository,
      );
      addTearDown(container.dispose);

      await container
          .read(deviceCommandControllerProvider.notifier)
          .loadDoorDetail(doorId: '12');
      repository.devices = const [
        DoorDevice(deviceId: '4', sn: 'new', deviceType: 'opener'),
      ];
      container
          .read(doorDevicesRefreshRequestProvider.notifier)
          .notify(const DoorDevicesRefreshRequest(doorId: '12', sequence: 1));
      await _settleBleSession();

      expect(
        container
            .read(deviceCommandControllerProvider)
            .doorDevices
            .single
            .deviceId,
        '4',
      );
      expect(
        container.read(deviceCommandControllerProvider).selectedDeviceId,
        '4',
      );
    },
  );

  test(
    'refresh reconciles the BLE pool and disconnects a removed device',
    () async {
      final gateway = _BleSessionGateway(
        discoveredDevices: const {
          'native-old': 'Noru_OLD',
          'native-new': 'Noru_NEW',
        },
      );
      final repository = _DoorDetailRepository(
        _doorDetail(),
        devices: const [
          DoorDevice(
            deviceId: 'old',
            sn: 'Noru_OLD',
            deviceType: 'opener',
            bleName: 'Noru_OLD',
          ),
        ],
      );
      final container = _createContainer(
        gateway: gateway,
        repository: repository,
      );
      addTearDown(container.dispose);
      final controller = container.read(
        deviceCommandControllerProvider.notifier,
      );

      await controller.loadDoorDetail(doorId: '12');
      await _settleBleSession();
      expect(controller.selectedHardwareDeviceId, 'native-old');

      repository.devices = const [
        DoorDevice(
          deviceId: 'new',
          sn: 'Noru_NEW',
          deviceType: 'opener',
          bleName: 'Noru_NEW',
        ),
      ];
      await controller.refreshDoorDevices(doorId: '12');
      await _settleBleSession();

      final state = container.read(deviceCommandControllerProvider);
      expect(gateway.disconnectedDeviceIds, contains('native-old'));
      expect(state.bleDeviceIds, isNot(contains('old')));
      expect(state.bleConnectionStatuses, isNot(contains('old')));
      expect(state.selectedDeviceId, 'new');
      expect(controller.selectedHardwareDeviceId, 'native-new');
    },
  );

  test('refresh reuses a retained connected device', () async {
    final gateway = _BleSessionGateway(
      discoveredDevices: const {'native-retained': 'Noru_RETAINED'},
    );
    final repository = _DoorDetailRepository(
      _doorDetail(),
      devices: const [
        DoorDevice(
          deviceId: 'retained',
          sn: 'Noru_RETAINED',
          deviceType: 'opener',
          bleName: 'Noru_RETAINED',
        ),
      ],
    );
    final container = _createContainer(
      gateway: gateway,
      repository: repository,
    );
    addTearDown(container.dispose);
    final controller = container.read(deviceCommandControllerProvider.notifier);

    await controller.loadDoorDetail(doorId: '12');
    await _settleBleSession();
    final connectCount = gateway.connectedDeviceIds.length;
    final authenticationCount = gateway.authenticatedDeviceIds.length;

    await controller.refreshDoorDevices(doorId: '12');
    await _settleBleSession();

    expect(gateway.disconnectedDeviceIds, isEmpty);
    expect(gateway.connectedDeviceIds, hasLength(connectCount));
    expect(gateway.authenticatedDeviceIds, hasLength(authenticationCount));
    expect(controller.selectedHardwareDeviceId, 'native-retained');
  });

  test('connects every BLE-capable backend device in one scan', () async {
    final gateway = _BleSessionGateway(
      discoveredDevices: const {
        'native-opener': 'Test door',
        'native-fbox': 'Fbox_TWO',
      },
    );
    final repository = _DoorDetailRepository(
      _doorDetail(),
      devices: const [
        DoorDevice(
          deviceId: 'opener',
          sn: 'Test door',
          deviceType: 'opener',
          bleName: 'Test door',
        ),
        DoorDevice(
          deviceId: 'fbox',
          sn: 'Fbox_TWO',
          deviceType: 'fbox',
          bleName: 'Fbox_TWO',
        ),
      ],
    );
    final deviceKeyRepository = _DeviceKeyRepository();
    final container = _createContainer(
      gateway: gateway,
      repository: repository,
      deviceKeyRepository: deviceKeyRepository,
    );
    addTearDown(container.dispose);

    await container
        .read(deviceCommandControllerProvider.notifier)
        .loadDoorDetail(doorId: '12');
    await _settleBleSession();

    expect(gateway.exactScanNames, ['']);
    expect(
      deviceKeyRepository.requestedSns,
      containsAll(<String>['Test door', 'Fbox_TWO']),
    );
    expect(
      gateway.connectedDeviceIds,
      containsAll(['native-opener', 'native-fbox']),
    );
    expect(
      container
          .read(deviceCommandControllerProvider)
          .bleConnectionStatuses
          .values,
      everyElement(DeviceBleConnectionStatus.connected),
    );
  });

  test('reuses an already-connected onboarding device', () async {
    final gateway = _BleSessionGateway();
    gateway.connectedBleDevices['native-onboarding'] = const ConnectedBleDevice(
      deviceId: 'native-onboarding',
      name: 'Test door',
      state: BleConnectionState.connected,
    );
    final container = _createContainer(gateway: gateway);
    addTearDown(container.dispose);

    await container
        .read(deviceCommandControllerProvider.notifier)
        .loadDoorDetail(doorId: '12');
    await _settleBleSession();

    expect(gateway.exactScanNames, isEmpty);
    expect(gateway.connectedDeviceIds, isEmpty);
    expect(gateway.authenticatedDeviceIds, isEmpty);
    expect(
      container.read(deviceCommandControllerProvider).bleDeviceId,
      'native-onboarding',
    );

    await gateway.writeCharacteristic(
      requestId: 'ignored-notification',
      deviceId: 'another-device',
      serviceUuid: 'service',
      characteristicUuid: 'characteristic',
      payload: Uint8List.fromList([1]),
    );
    await _settleBleSession();
    expect(
      container
          .read(deviceCommandControllerProvider)
          .lastSelectedBleNotification,
      isNull,
    );

    await gateway.writeCharacteristic(
      requestId: 'selected-notification',
      deviceId: 'native-onboarding',
      serviceUuid: 'service',
      characteristicUuid: 'characteristic',
      payload: Uint8List.fromList([2]),
    );
    await _settleBleSession();
    expect(
      container
          .read(deviceCommandControllerProvider)
          .lastSelectedBleNotification
          ?.requestId,
      'selected-notification',
    );
  });

  test('selection routes commands without reconnecting', () async {
    final gateway = _BleSessionGateway(
      discoveredDevices: const {
        'native-opener': 'Test door',
        'native-fbox': 'Fbox_TWO',
      },
    );
    final repository = _DoorDetailRepository(
      _doorDetail(),
      devices: const [
        DoorDevice(
          deviceId: 'opener',
          sn: 'Test door',
          deviceType: 'opener',
          bleName: 'Test door',
        ),
        DoorDevice(
          deviceId: 'fbox',
          sn: 'Fbox_TWO',
          deviceType: 'fbox',
          bleName: 'Fbox_TWO',
        ),
      ],
    );
    final container = _createContainer(
      gateway: gateway,
      repository: repository,
    );
    addTearDown(container.dispose);
    final controller = container.read(deviceCommandControllerProvider.notifier);

    await controller.loadDoorDetail(doorId: '12');
    await _settleBleSession();
    final connectCount = gateway.connectedDeviceIds.length;
    controller.selectDevice('fbox');
    await controller.runAction(
      deviceId: 'stale-device',
      action: DeviceCommandAction.openDoor,
    );

    expect(gateway.connectedDeviceIds, hasLength(connectCount));
    expect(gateway.commandDeviceIds, ['native-fbox']);
  });

  test('logs how a 0x0202 report is aligned with the selected UI', () async {
    final gateway = _BleSessionGateway();
    final logger = _RecordingLogger();
    final container = _createContainer(gateway: gateway, logger: logger);
    addTearDown(container.dispose);

    await container
        .read(deviceCommandControllerProvider.notifier)
        .loadDoorDetail(doorId: '12');
    await _settleBleSession();

    gateway.emitDeviceAttributeSnapshot(
      DeviceAttributeSnapshot(
        requestId: 'attribute-report-1',
        deviceId: 'target-device',
        sequence: 7,
        timestampMillis: 1,
        origin: DeviceAttributeReportOrigin.activeReport,
        attributes: [
          DeviceAttribute(id: 0x2715, value: Uint8List.fromList([0x03])),
          DeviceAttribute(id: 0x271C, value: Uint8List.fromList([50])),
        ],
      ),
    );
    await _settleBleSession();

    final received = logger.records.singleWhere(
      (record) => record.message == 'device_attribute_snapshot_received',
    );
    expect(received.context['sourceDeviceId'], 'target-device');
    expect(received.context['selectedHardwareDeviceId'], 'target-device');

    final parsed = logger.records.singleWhere(
      (record) => record.message == 'device_attribute_report_parsed',
    );
    expect(parsed.context['relevantRaw'], ['0x2715=[0x03]', '0x271C=[0x32]']);
    expect(parsed.context['doorStatusParsed'], 'opening');
    expect(parsed.context['doorPositionParsedPercent'], 50.0);
    expect(parsed.context['uiUpdate'], 'applied');
  });

  test(
    'clears realtime state and refreshes door detail after disconnect',
    () async {
      final gateway = _BleSessionGateway();
      final repository = _DoorDetailRepository(_doorDetail());
      final container = _createContainer(
        gateway: gateway,
        repository: repository,
      );
      addTearDown(container.dispose);

      await container
          .read(deviceCommandControllerProvider.notifier)
          .loadDoorDetail(doorId: '12');
      await _settleBleSession();

      gateway.emitDeviceAttributeSnapshot(
        DeviceAttributeSnapshot(
          deviceId: 'target-device',
          sequence: 1,
          timestampMillis: 1,
          origin: DeviceAttributeReportOrigin.activeReport,
          attributes: [
            DeviceAttribute(id: 0x2715, value: Uint8List.fromList([0x03])),
            DeviceAttribute(id: 0x271C, value: Uint8List.fromList([50])),
          ],
        ),
      );
      await _settleBleSession();
      expect(
        container
            .read(deviceCommandControllerProvider)
            .doorRealtimeState
            ?.positionPercent,
        50,
      );

      repository.detail = DoorDetail(
        id: '12',
        name: 'Test door',
        doorState: DoorState.open,
        doorStateLabel: 'Open',
        positionPercent: 100,
        operatedCycles: 0,
        remainingCycles: 0,
      );
      gateway.emitBleConnectionEvent(
        const BleConnectionEvent(
          requestId: 'disconnect-event',
          deviceId: 'target-device',
          state: BleConnectionState.disconnected,
        ),
      );
      await _settleBleSession();

      final state = container.read(deviceCommandControllerProvider);
      expect(state.doorRealtimeState, isNull);
      expect(state.lastSelectedAttributeSnapshot, isNull);
      expect(state.lastSelectedBleNotification, isNull);
      expect(state.doorDetail?.doorState, DoorState.open);
      expect(state.doorDetail?.positionPercent, 100);
      expect(repository.doorDetailRequestCount, 2);
    },
  );
}

ProviderContainer _createContainer({
  required _BleSessionGateway gateway,
  DoorDetail? doorDetail,
  _DoorDetailRepository? repository,
  _DeviceKeyRepository? deviceKeyRepository,
  AppLogger? logger,
  Duration scanDuration = const Duration(seconds: 10),
}) {
  return ProviderContainer(
    overrides: [
      deviceCommandHardwareGatewayProvider.overrideWithValue(gateway),
      doorDetailRepositoryProvider.overrideWithValue(
        repository ?? _DoorDetailRepository(doorDetail ?? _doorDetail()),
      ),
      addDeviceOnboardingRepositoryProvider.overrideWithValue(
        deviceKeyRepository ?? _DeviceKeyRepository(),
      ),
      deviceCommandBleScanDurationProvider.overrideWithValue(scanDuration),
      if (logger != null) appLoggerProvider.overrideWithValue(logger),
    ],
  );
}

Future<void> _settleBleSession() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

DoorDetail _doorDetail({String name = 'Test door'}) {
  return DoorDetail(
    id: '12',
    name: name,
    doorState: DoorState.closed,
    doorStateLabel: 'Closed',
    operatedCycles: 0,
    remainingCycles: 0,
  );
}

class _DoorDetailRepository implements DoorDetailRepository {
  _DoorDetailRepository(
    this.detail, {
    this.devices = const [
      DoorDevice(
        deviceId: '3',
        sn: 'Test door',
        deviceType: 'opener',
        bleName: 'Test door',
      ),
    ],
  });

  DoorDetail detail;
  List<DoorDevice> devices;
  var doorDetailRequestCount = 0;

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) async {
    doorDetailRequestCount += 1;
    return detail;
  }

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) async => devices;

  @override
  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) => throw UnimplementedError();
}

class _DeviceKeyRepository implements AddDeviceOnboardingRepository {
  final List<String> requestedSns = <String>[];

  @override
  Future<void> validateBindingStatus({
    required String sn,
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<OnboardedForceDoor> addForceDoor({
    required String sn,
    String? doorId,
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<OnboardingDeviceKey> fetchDeviceKey({
    required String sn,
    required String requestId,
  }) async {
    requestedSns.add(sn);
    return OnboardingDeviceKey(
      sn: sn,
      aesKey: '0123456789abcdef0123456789abcdef',
      aesKeyVersion: 'test',
    );
  }
}

class _RecordingLogger implements AppLogger {
  final List<_LogRecord> records = <_LogRecord>[];

  @override
  void info(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {
    records.add(_LogRecord(message, context));
  }

  @override
  void warning(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {
    records.add(_LogRecord(message, context));
  }

  @override
  void error(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    records.add(_LogRecord(message, context));
  }
}

class _LogRecord {
  const _LogRecord(this.message, this.context);

  final String message;
  final Map<String, Object?> context;
}

class _BleSessionGateway extends MockHardwareGateway {
  _BleSessionGateway({
    this.emitTargetDevice = true,
    this.authenticationSucceeds = true,
    Map<String, String>? discoveredDevices,
  }) : discoveredDevices =
           discoveredDevices ?? const {'target-device': 'Test door'};

  final bool emitTargetDevice;
  final bool authenticationSucceeds;
  final Map<String, String> discoveredDevices;
  final StreamController<BleDevice> _scanResults =
      StreamController<BleDevice>.broadcast();
  final List<String> exactScanNames = <String>[];
  final List<String> connectedDeviceIds = <String>[];
  final List<String> authenticatedDeviceIds = <String>[];
  final List<String> disconnectedDeviceIds = <String>[];
  final List<String> commandDeviceIds = <String>[];
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
      for (final entry in discoveredDevices.entries) {
        _scanResults.add(
          BleDevice(
            requestId: requestId,
            scanSessionId: 'session',
            id: entry.key,
            name: entry.value,
            sn: entry.value,
            rssi: -40,
            seenAtMillis: 0,
          ),
        );
      }
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
    final name = discoveredDevices[deviceId];
    connectedBleDevices[deviceId] = ConnectedBleDevice(
      deviceId: deviceId,
      name: name,
      state: BleConnectionState.connected,
    );
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
    required String aesKeyVersion,
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
    connectedBleDevices.remove(deviceId);
    return BleConnectionEvent(
      requestId: requestId,
      deviceId: deviceId,
      state: BleConnectionState.disconnected,
    );
  }

  @override
  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  }) async {
    commandDeviceIds.add(deviceId);
    return CommandResult(
      requestId: requestId,
      deviceId: deviceId,
      command: command,
      accepted: true,
    );
  }
}
