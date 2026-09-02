import 'dart:async';
import 'dart:typed_data';

import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/logging/providers.dart';
import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/features/add_device/domain/entities/onboarded_force_door.dart';
import 'package:flinx/features/add_device/domain/entities/onboarding_device_key.dart';
import 'package:flinx/features/add_device/domain/repositories/add_device_onboarding_repository.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/domain/entities/door_detail.dart';
import 'package:flinx/features/device_control/domain/entities/about_device_info.dart';
import 'package:flinx/features/device_control/domain/entities/door_device.dart';
import 'package:flinx/features/device_control/domain/entities/remote_door_command.dart';
import 'package:flinx/features/device_control/domain/repositories/door_detail_repository.dart';
import 'package:flinx/features/device_control/domain/repositories/remote_door_command_repository.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'ignores an older door detail response after the door changes',
    () async {
      final repository = _DelayedByDoorDetailRepository();
      final container = _createContainer(
        gateway: _BleSessionGateway(emitTargetDevice: false),
        repository: repository,
      );
      addTearDown(container.dispose);
      final controller = container.read(
        deviceCommandControllerProvider.notifier,
      );

      final firstLoad = controller.loadDoorDetail(doorId: '12');
      await _settleBleSession();
      final secondLoad = controller.loadDoorDetail(doorId: '13');
      await _settleBleSession();

      repository.complete('13');
      await secondLoad;
      expect(
        container.read(deviceCommandControllerProvider).doorDetail?.id,
        '13',
      );

      repository.complete('12');
      await firstLoad;
      expect(
        container.read(deviceCommandControllerProvider).doorDetail?.id,
        '13',
      );
      expect(
        container.read(deviceCommandControllerProvider).isLoadingDoorDetail,
        isFalse,
      );
    },
  );

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

  test('selects the initial device by type priority', () async {
    final cases = <({List<DoorDevice> devices, String? expectedDeviceId})>[
      (
        devices: const [
          DoorDevice(deviceId: 'fbox', sn: 'fbox', deviceType: 'fbox'),
          DoorDevice(deviceId: 'dongle', sn: 'dongle', deviceType: 'dongle'),
          DoorDevice(
            deviceId: 'evolution',
            sn: 'evolution',
            deviceType: 'evolution',
          ),
          DoorDevice(deviceId: 'opener', sn: 'opener', deviceType: ' OpEnEr '),
        ],
        expectedDeviceId: 'opener',
      ),
      (
        devices: const [
          DoorDevice(deviceId: 'fbox', sn: 'fbox', deviceType: 'fbox'),
          DoorDevice(deviceId: 'dongle', sn: 'dongle', deviceType: 'dongle'),
          DoorDevice(
            deviceId: 'evolution',
            sn: 'evolution',
            deviceType: 'evolution',
          ),
        ],
        expectedDeviceId: 'evolution',
      ),
      (
        devices: const [
          DoorDevice(deviceId: 'fbox', sn: 'fbox', deviceType: 'fbox'),
          DoorDevice(deviceId: 'dongle', sn: 'dongle', deviceType: 'dongle'),
        ],
        expectedDeviceId: 'dongle',
      ),
      (
        devices: const [
          DoorDevice(deviceId: 'fbox', sn: 'fbox', deviceType: 'fbox'),
        ],
        expectedDeviceId: 'fbox',
      ),
      (
        devices: const [
          DoorDevice(deviceId: 'other', sn: 'other', deviceType: 'video'),
          DoorDevice(deviceId: 'unknown', sn: 'unknown', deviceType: 'other'),
        ],
        expectedDeviceId: 'other',
      ),
      (devices: const <DoorDevice>[], expectedDeviceId: null),
    ];

    for (final testCase in cases) {
      final container = _createContainer(
        gateway: _BleSessionGateway(),
        repository: _DoorDetailRepository(
          _doorDetail(),
          devices: testCase.devices,
        ),
      );
      addTearDown(container.dispose);

      await container
          .read(deviceCommandControllerProvider.notifier)
          .loadDoorDetail(doorId: '12');

      expect(
        container.read(deviceCommandControllerProvider).selectedDeviceId,
        testCase.expectedDeviceId,
      );
    }
  });

  test('preferred device overrides the default type priority', () async {
    final container = _createContainer(
      gateway: _BleSessionGateway(),
      repository: _DoorDetailRepository(
        _doorDetail(),
        devices: const [
          DoorDevice(deviceId: 'opener', sn: 'opener', deviceType: 'opener'),
          DoorDevice(deviceId: 'fbox', sn: 'fbox', deviceType: 'fbox'),
        ],
      ),
    );
    addTearDown(container.dispose);

    await container
        .read(deviceCommandControllerProvider.notifier)
        .loadDoorDetail(doorId: '12', preferredDeviceId: ' fbox ');

    expect(
      container.read(deviceCommandControllerProvider).selectedDeviceId,
      'fbox',
    );
  });

  test(
    'clears a stale selection when the reloaded device list is empty',
    () async {
      final repository = _DoorDetailRepository(
        _doorDetail(),
        devices: const [
          DoorDevice(deviceId: 'opener', sn: 'opener', deviceType: 'opener'),
        ],
      );
      final container = _createContainer(
        gateway: _BleSessionGateway(),
        repository: repository,
      );
      addTearDown(container.dispose);
      final controller = container.read(
        deviceCommandControllerProvider.notifier,
      );

      await controller.loadDoorDetail(doorId: '12');
      expect(
        container.read(deviceCommandControllerProvider).selectedDeviceId,
        'opener',
      );

      repository.devices = const <DoorDevice>[];
      await controller.loadDoorDetail(doorId: '13');

      expect(
        container.read(deviceCommandControllerProvider).selectedDeviceId,
        isNull,
      );
    },
  );

  test(
    'refresh falls back to type priority when selection is removed',
    () async {
      final repository = _DoorDetailRepository(
        _doorDetail(),
        devices: const [
          DoorDevice(deviceId: 'fbox', sn: 'fbox', deviceType: 'fbox'),
        ],
      );
      final container = _createContainer(
        gateway: _BleSessionGateway(),
        repository: repository,
      );
      addTearDown(container.dispose);
      final controller = container.read(
        deviceCommandControllerProvider.notifier,
      );

      await controller.loadDoorDetail(doorId: '12');
      expect(
        container.read(deviceCommandControllerProvider).selectedDeviceId,
        'fbox',
      );

      repository.devices = const [
        DoorDevice(deviceId: 'other', sn: 'other', deviceType: 'video'),
        DoorDevice(deviceId: 'dongle', sn: 'dongle', deviceType: 'dongle'),
        DoorDevice(
          deviceId: 'evolution',
          sn: 'evolution',
          deviceType: 'evolution',
        ),
      ];
      await controller.refreshDoorDevices(doorId: '12');

      expect(
        container.read(deviceCommandControllerProvider).selectedDeviceId,
        'evolution',
      );
    },
  );

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

  test('refreshes door detail when a settings change requests it', () async {
    final repository = _DoorDetailRepository(_doorDetail());
    final container = _createContainer(
      gateway: _BleSessionGateway(),
      repository: repository,
    );
    addTearDown(container.dispose);

    await container
        .read(deviceCommandControllerProvider.notifier)
        .loadDoorDetail(doorId: '12');
    await _settleBleSession();
    expect(repository.doorDetailRequestCount, 1);

    container
        .read(doorDetailRefreshRequestProvider.notifier)
        .notify(const DoorDetailRefreshRequest(doorId: '12'));
    await _settleBleSession();

    expect(repository.doorDetailRequestCount, 2);
  });

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
    final result = await controller.runAction(
      deviceId: 'stale-device',
      action: DeviceCommandAction.openDoor,
    );

    expect(gateway.connectedDeviceIds, hasLength(connectCount));
    expect(gateway.commandDeviceIds, ['native-fbox']);
    expect(result?.succeeded, isTrue);
    expect(result?.transport, DeviceCommandTransport.bluetooth);
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
          DeviceAttribute(id: 0x2715, value: Uint8List.fromList([0x00])),
          DeviceAttribute(id: 0x271C, value: Uint8List.fromList([100])),
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
    expect(parsed.context['relevantRaw'], ['0x2715=[0x00]', '0x271C=[0x64]']);
    expect(parsed.context['doorMotorParsed'], 'opening');
    expect(parsed.context['doorPositionParsedPercent'], 100.0);
    expect(parsed.context['uiDoorStatusAfter'], 'open');
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
            DeviceAttribute(id: 0x2715, value: Uint8List.fromList([0x00])),
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

  test('uses door detail state polling without BLE', () async {
    final gateway = _BleSessionGateway(emitTargetDevice: false);
    final detailRepository = _DoorDetailRepository(_doorDetail());
    detailRepository.detailResponses.addAll([
      _doorDetail(),
      DoorDetail(
        id: '12',
        name: 'Test door',
        doorState: DoorState.open,
        doorStateLabel: 'Open',
        positionPercent: 100,
        operatedCycles: 0,
        remainingCycles: 0,
      ),
    ]);
    final remoteRepository = _RemoteDoorCommandRepository([
      _remoteCommand(RemoteDoorCommandStatus.processing),
      _remoteCommand(RemoteDoorCommandStatus.succeeded),
    ]);
    final container = _createContainer(
      gateway: gateway,
      repository: detailRepository,
      remoteRepository: remoteRepository,
      scanDuration: Duration.zero,
      remotePollInterval: Duration.zero,
    );
    addTearDown(container.dispose);
    final controller = container.read(deviceCommandControllerProvider.notifier);

    await controller.loadDoorDetail(doorId: '12');
    await _settleBleSession();
    final result = await controller.runAction(
      deviceId: 'ignored-without-ble',
      action: DeviceCommandAction.openDoor,
    );
    await _settleBleSession();

    final state = container.read(deviceCommandControllerProvider);
    expect(gateway.commandDeviceIds, isEmpty);
    expect(remoteRepository.submittedActions, [RemoteDoorCommandAction.open]);
    expect(remoteRepository.requestIds.toSet(), hasLength(1));
    expect(state.pendingAction, isNull);
    expect(state.commandFeedback?.kind, DeviceCommandFeedbackKind.succeeded);
    expect(state.doorDetail?.doorState, DoorState.open);
    expect(state.doorDetail?.positionPercent, 100);
    expect(result?.succeeded, isTrue);
    expect(result?.transport, DeviceCommandTransport.app);
  });

  test('does not remotely execute unsupported actions without BLE', () async {
    final gateway = _BleSessionGateway(emitTargetDevice: false);
    final remoteRepository = _RemoteDoorCommandRepository([]);
    final container = _createContainer(
      gateway: gateway,
      remoteRepository: remoteRepository,
      scanDuration: Duration.zero,
      remotePollInterval: Duration.zero,
    );
    addTearDown(container.dispose);
    final controller = container.read(deviceCommandControllerProvider.notifier);

    await controller.loadDoorDetail(doorId: '12');
    await _settleBleSession();
    await controller.runAction(
      deviceId: 'ignored-without-ble',
      action: DeviceCommandAction.partialOpenDoor,
    );

    expect(remoteRepository.submittedActions, isEmpty);
    expect(
      container.read(deviceCommandControllerProvider).commandFeedback?.kind,
      DeviceCommandFeedbackKind.requiresBluetooth,
    );
  });

  test('confirms remote light on by polling door detail led status', () async {
    final detailRepository = _DoorDetailRepository(_doorDetail(ledStatus: 1));
    detailRepository.detailResponses.addAll([
      _doorDetail(ledStatus: 1),
      _doorDetail(ledStatus: 1),
      _doorDetail(ledStatus: 2),
    ]);
    final remoteRepository = _RemoteDoorCommandRepository([
      _remoteCommand(RemoteDoorCommandStatus.processing),
    ]);
    final container = _createContainer(
      gateway: _BleSessionGateway(emitTargetDevice: false),
      repository: detailRepository,
      remoteRepository: remoteRepository,
      scanDuration: Duration.zero,
      remotePollInterval: Duration.zero,
    );
    addTearDown(container.dispose);
    final controller = container.read(deviceCommandControllerProvider.notifier);

    await controller.loadDoorDetail(doorId: '12');
    await _settleBleSession();
    await controller.runAction(
      deviceId: 'ignored-without-ble',
      action: DeviceCommandAction.turnLightOn,
    );

    final state = container.read(deviceCommandControllerProvider);
    expect(detailRepository.doorDetailRequestCount, 3);
    expect(state.pendingAction, isNull);
    expect(state.commandFeedback?.kind, DeviceCommandFeedbackKind.succeeded);
    expect(state.doorDetail?.ledStatus, 2);
  });

  test('confirms remote light off only when led status becomes one', () async {
    final detailRepository = _DoorDetailRepository(_doorDetail(ledStatus: 2));
    detailRepository.detailResponses.addAll([
      _doorDetail(ledStatus: 2),
      _doorDetail(ledStatus: 0),
      _doorDetail(ledStatus: 1),
    ]);
    final container = _createContainer(
      gateway: _BleSessionGateway(emitTargetDevice: false),
      repository: detailRepository,
      remoteRepository: _RemoteDoorCommandRepository([
        _remoteCommand(RemoteDoorCommandStatus.processing),
      ]),
      scanDuration: Duration.zero,
      remotePollInterval: Duration.zero,
    );
    addTearDown(container.dispose);
    final controller = container.read(deviceCommandControllerProvider.notifier);

    await controller.loadDoorDetail(doorId: '12');
    await _settleBleSession();
    await controller.runAction(
      deviceId: 'ignored-without-ble',
      action: DeviceCommandAction.turnLightOff,
    );

    final state = container.read(deviceCommandControllerProvider);
    expect(detailRepository.doorDetailRequestCount, 3);
    expect(state.commandFeedback?.kind, DeviceCommandFeedbackKind.succeeded);
    expect(state.doorDetail?.ledStatus, 1);
  });

  test(
    'times out remote light when detail never reaches target status',
    () async {
      final detailRepository = _DoorDetailRepository(_doorDetail(ledStatus: 1));
      detailRepository.detailResponses.addAll([
        _doorDetail(ledStatus: 1),
        _doorDetail(ledStatus: 0),
        _doorDetail(),
        _doorDetail(ledStatus: 1),
      ]);
      final container = _createContainer(
        gateway: _BleSessionGateway(emitTargetDevice: false),
        repository: detailRepository,
        remoteRepository: _RemoteDoorCommandRepository([
          _remoteCommand(RemoteDoorCommandStatus.succeeded),
        ]),
        scanDuration: Duration.zero,
        remotePollInterval: Duration.zero,
        remotePollMaxAttempts: 2,
      );
      addTearDown(container.dispose);
      final controller = container.read(
        deviceCommandControllerProvider.notifier,
      );

      await controller.loadDoorDetail(doorId: '12');
      await _settleBleSession();
      final result = await controller.runAction(
        deviceId: 'ignored-without-ble',
        action: DeviceCommandAction.turnLightOn,
      );

      final state = container.read(deviceCommandControllerProvider);
      expect(detailRepository.doorDetailRequestCount, 4);
      expect(state.pendingAction, isNull);
      expect(
        state.commandFeedback?.kind,
        DeviceCommandFeedbackKind.remoteTimeout,
      );
      expect(state.doorDetail?.ledStatus, 1);
      expect(result?.succeeded, isFalse);
      expect(result?.transport, DeviceCommandTransport.app);
    },
  );

  test('clears pending state when a remote request fails', () async {
    final container = _createContainer(
      gateway: _BleSessionGateway(emitTargetDevice: false),
      remoteRepository: const _FailingRemoteDoorCommandRepository(),
      scanDuration: Duration.zero,
      remotePollInterval: Duration.zero,
    );
    addTearDown(container.dispose);
    final controller = container.read(deviceCommandControllerProvider.notifier);

    await controller.loadDoorDetail(doorId: '12');
    await _settleBleSession();
    await controller.runAction(
      deviceId: 'ignored-without-ble',
      action: DeviceCommandAction.closeDoor,
    );

    final state = container.read(deviceCommandControllerProvider);
    expect(state.pendingAction, isNull);
    expect(
      state.commandFeedback?.kind,
      DeviceCommandFeedbackKind.networkFailure,
    );
  });

  test(
    'stops remote state polling after six attempts and refreshes detail',
    () async {
      final detailRepository = _DoorDetailRepository(_doorDetail());
      final remoteRepository = _RemoteDoorCommandRepository([
        _remoteCommand(RemoteDoorCommandStatus.processing),
      ]);
      detailRepository.detailResponses.addAll(
        List<DoorDetail>.generate(7, (_) => _doorDetail()),
      );
      final container = _createContainer(
        gateway: _BleSessionGateway(emitTargetDevice: false),
        repository: detailRepository,
        remoteRepository: remoteRepository,
        scanDuration: Duration.zero,
        remotePollInterval: Duration.zero,
      );
      addTearDown(container.dispose);
      final controller = container.read(
        deviceCommandControllerProvider.notifier,
      );

      await controller.loadDoorDetail(doorId: '12');
      await _settleBleSession();
      await controller.runAction(
        deviceId: 'ignored-without-ble',
        action: DeviceCommandAction.openDoor,
      );

      final state = container.read(deviceCommandControllerProvider);
      expect(detailRepository.doorDetailRequestCount, 8);
      expect(state.pendingAction, isNull);
      expect(state.commandFeedback, isNull);
      expect(state.doorDetail?.doorState, DoorState.closed);
    },
  );

  test('does not use the remote command status as completion signal', () async {
    final remoteRepository = _RemoteDoorCommandRepository([
      _remoteCommand(RemoteDoorCommandStatus.unconfirmed),
    ]);
    final container = _createContainer(
      gateway: _BleSessionGateway(emitTargetDevice: false),
      remoteRepository: remoteRepository,
      scanDuration: Duration.zero,
      remotePollInterval: Duration.zero,
    );
    addTearDown(container.dispose);
    final controller = container.read(deviceCommandControllerProvider.notifier);

    await controller.loadDoorDetail(doorId: '12');
    await _settleBleSession();
    await controller.runAction(
      deviceId: 'ignored-without-ble',
      action: DeviceCommandAction.openDoor,
    );

    expect(
      container.read(deviceCommandControllerProvider).commandFeedback,
      isNull,
    );
  });
}

ProviderContainer _createContainer({
  required _BleSessionGateway gateway,
  DoorDetail? doorDetail,
  DoorDetailRepository? repository,
  _DeviceKeyRepository? deviceKeyRepository,
  RemoteDoorCommandRepository? remoteRepository,
  AppLogger? logger,
  Duration scanDuration = const Duration(seconds: 10),
  Duration remotePollInterval = const Duration(seconds: 1),
  int remotePollMaxAttempts = 6,
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
      if (remoteRepository != null)
        remoteDoorCommandRepositoryProvider.overrideWithValue(remoteRepository),
      deviceCommandBleScanDurationProvider.overrideWithValue(scanDuration),
      deviceCommandRemotePollIntervalProvider.overrideWithValue(
        remotePollInterval,
      ),
      deviceCommandRemotePollMaxAttemptsProvider.overrideWithValue(
        remotePollMaxAttempts,
      ),
      if (logger != null) appLoggerProvider.overrideWithValue(logger),
    ],
  );
}

Future<void> _settleBleSession() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

DoorDetail _doorDetail({String name = 'Test door', int? ledStatus}) {
  return DoorDetail(
    id: '12',
    name: name,
    doorState: DoorState.closed,
    doorStateLabel: 'Closed',
    operatedCycles: 0,
    remainingCycles: 0,
    ledStatus: ledStatus,
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
  final List<DoorDetail> detailResponses = <DoorDetail>[];
  List<DoorDevice> devices;
  var doorDetailRequestCount = 0;

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) async {
    doorDetailRequestCount += 1;
    if (detailResponses.isNotEmpty) {
      detail = detailResponses.removeAt(0);
    }
    return detail;
  }

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) async => devices;

  @override
  Future<AboutDeviceInfo> fetchAboutDeviceInfo({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) => throw UnimplementedError();
}

class _DelayedByDoorDetailRepository implements DoorDetailRepository {
  final Map<String, Completer<DoorDetail>> _detailCompleters = {};
  final Map<String, Completer<List<DoorDevice>>> _deviceCompleters = {};

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) {
    return _detailCompleters
        .putIfAbsent(doorId, Completer<DoorDetail>.new)
        .future;
  }

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) {
    return _deviceCompleters
        .putIfAbsent(doorId, Completer<List<DoorDevice>>.new)
        .future;
  }

  @override
  Future<AboutDeviceInfo> fetchAboutDeviceInfo({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) => throw UnimplementedError();

  void complete(String doorId) {
    _detailCompleters[doorId]!.complete(
      DoorDetail(
        id: doorId,
        name: 'Door $doorId',
        doorState: DoorState.closed,
        doorStateLabel: 'Closed',
        operatedCycles: 0,
        remainingCycles: 0,
      ),
    );
    _deviceCompleters[doorId]!.complete(const <DoorDevice>[]);
  }
}

RemoteDoorCommand _remoteCommand(RemoteDoorCommandStatus status) {
  return RemoteDoorCommand(
    commandId: 'command-1',
    doorId: '12',
    action: RemoteDoorCommandAction.open,
    status: status,
  );
}

class _RemoteDoorCommandRepository implements RemoteDoorCommandRepository {
  _RemoteDoorCommandRepository(this.responses);

  final List<RemoteDoorCommand> responses;
  final List<RemoteDoorCommandAction> submittedActions =
      <RemoteDoorCommandAction>[];
  final List<String> requestIds = <String>[];

  @override
  Future<RemoteDoorCommand> submitCommand({
    required String doorId,
    required RemoteDoorCommandAction action,
    required String requestId,
  }) async {
    submittedActions.add(action);
    requestIds.add(requestId);
    return responses.removeAt(0);
  }
}

class _FailingRemoteDoorCommandRepository
    implements RemoteDoorCommandRepository {
  const _FailingRemoteDoorCommandRepository();

  @override
  Future<RemoteDoorCommand> submitCommand({
    required String doorId,
    required RemoteDoorCommandAction action,
    required String requestId,
  }) {
    throw AppError(
      code: AppErrorCode.networkUnavailable,
      messageKey: 'remote_door_command_network_unavailable',
      requestId: requestId,
      retryable: true,
    );
  }
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
    int? sceneId,
    required int doorType,
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
