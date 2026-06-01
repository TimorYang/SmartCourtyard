import 'dart:async';
import 'dart:typed_data';

import 'hardware_gateway.dart';
import 'hardware_models.dart';

class MockHardwareGateway implements HardwareGateway {
  MockHardwareGateway()
    : _scanController = StreamController<BleDevice>.broadcast(),
      _connectionController = StreamController<BleConnectionEvent>.broadcast(),
      _notificationController = StreamController<BleNotification>.broadcast(),
      _nativeErrorController =
          StreamController<NativeHardwareError>.broadcast();

  final StreamController<BleDevice> _scanController;
  final StreamController<BleConnectionEvent> _connectionController;
  final StreamController<BleNotification> _notificationController;
  final StreamController<NativeHardwareError> _nativeErrorController;

  @override
  Stream<BleDevice> get bleScanResults => _scanController.stream;

  @override
  Stream<BleConnectionEvent> get bleConnectionEvents =>
      _connectionController.stream;

  @override
  Stream<BleNotification> get bleNotifications =>
      _notificationController.stream;

  @override
  Stream<NativeHardwareError> get nativeErrors => _nativeErrorController.stream;

  @override
  Future<PermissionSnapshot> getPermissionSnapshot() async {
    return const PermissionSnapshot(
      bluetoothGranted: true,
      cameraGranted: true,
      localNetworkGranted: true,
      notificationGranted: true,
    );
  }

  @override
  Future<PermissionSnapshot> requestPermissions({
    required List<PermissionKind> permissions,
  }) async {
    return getPermissionSnapshot();
  }

  @override
  Future<List<DeviceSummary>> readDevices() async {
    return [
      DeviceSummary(
        id: 'mock-garage-door',
        name: 'Garage Door',
        onlineState: DeviceOnlineState.online,
        bleState: BleConnectionState.connected,
        doorState: DoorState.closed,
        cycleCount: 328,
        remainingLifePercent: 91,
        lastSeenAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<void> startBleScan({
    required String requestId,
    BleScanFilter filter = const BleScanFilter(),
  }) async {
    final device = BleDevice(
      requestId: requestId,
      scanSessionId: '$requestId-mock-session',
      id: 'mock-ble-device',
      name: filter.exactName ?? 'FLINX Mock Device',
      rssi: -52,
      seenAtMillis: DateTime.now().millisecondsSinceEpoch,
      advertisementServiceUuids: filter.serviceUuids,
      manufacturerData: Uint8List.fromList(<int>[0x46, 0x4c, 0x49, 0x4e, 0x58]),
    );
    _scanController.add(device);
  }

  @override
  Future<void> stopBleScan({required String requestId}) async {}

  @override
  Future<BleConnectionEvent> connectBleDevice({
    required String requestId,
    required String deviceId,
  }) async {
    final connecting = BleConnectionEvent(
      requestId: requestId,
      deviceId: deviceId,
      state: BleConnectionState.connecting,
    );
    _connectionController.add(connecting);

    final connected = BleConnectionEvent(
      requestId: requestId,
      deviceId: deviceId,
      state: BleConnectionState.connected,
    );
    _connectionController.add(connected);
    return connected;
  }

  @override
  Future<BleConnectionEvent> disconnectBleDevice({
    required String requestId,
    required String deviceId,
  }) async {
    final event = BleConnectionEvent(
      requestId: requestId,
      deviceId: deviceId,
      state: BleConnectionState.disconnected,
    );
    _connectionController.add(event);
    return event;
  }

  @override
  Future<BleServices> discoverServices({
    required String requestId,
    required String deviceId,
  }) async {
    return BleServices(
      requestId: requestId,
      deviceId: deviceId,
      services: const <BleService>[
        BleService(
          serviceUuid: 'FFF0',
          characteristics: <BleCharacteristic>[
            BleCharacteristic(
              serviceUuid: 'FFF0',
              characteristicUuid: 'FFF1',
              canRead: true,
              canWriteWithResponse: true,
              canWriteWithoutResponse: true,
              canNotify: true,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<BleReadResult> readCharacteristic({
    required String requestId,
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    return BleReadResult(
      requestId: requestId,
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      payload: Uint8List.fromList(<int>[0x01, 0x02]),
    );
  }

  @override
  Future<BleWriteResult> writeCharacteristic({
    required String requestId,
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    BleWriteType writeType = BleWriteType.withResponse,
  }) async {
    _notificationController.add(
      BleNotification(
        requestId: requestId,
        deviceId: deviceId,
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        payload: Uint8List.fromList(payload),
        timestampMillis: DateTime.now().millisecondsSinceEpoch,
        sequenceNumber: 1,
      ),
    );

    return BleWriteResult(
      requestId: requestId,
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      accepted: true,
    );
  }

  @override
  Future<BleWriteResult> setCharacteristicNotify({
    required String requestId,
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required bool enabled,
  }) async {
    return BleWriteResult(
      requestId: requestId,
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      accepted: true,
    );
  }

  @override
  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  }) async {
    return CommandResult(
      requestId: requestId,
      deviceId: deviceId,
      command: command,
      accepted: true,
    );
  }
}
