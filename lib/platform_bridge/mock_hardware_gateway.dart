import 'dart:async';
import 'dart:typed_data';

import 'hardware_gateway.dart';
import 'hardware_models.dart';

class MockHardwareGateway implements HardwareGateway {
  MockHardwareGateway({
    this.autoCloseAttributeId = 0x2712,
    this.autoCloseValue = 0,
  }) : _scanController = StreamController<BleDevice>.broadcast(),
       _connectionController = StreamController<BleConnectionEvent>.broadcast(),
       _notificationController = StreamController<BleNotification>.broadcast(),
       _nativeErrorController =
           StreamController<NativeHardwareError>.broadcast(),
       _diagnosticController = StreamController<BleDiagnosticEvent>.broadcast(),
       _attributeController =
           StreamController<DeviceAttributeSnapshot>.broadcast(),
       _attributes = _buildAttributes(
         autoCloseAttributeId: autoCloseAttributeId,
         autoCloseValue: autoCloseValue,
       );

  final StreamController<BleDevice> _scanController;
  final StreamController<BleConnectionEvent> _connectionController;
  final StreamController<BleNotification> _notificationController;
  final StreamController<NativeHardwareError> _nativeErrorController;
  final StreamController<BleDiagnosticEvent> _diagnosticController;
  final StreamController<DeviceAttributeSnapshot> _attributeController;
  final int autoCloseAttributeId;
  final int autoCloseValue;
  final Map<int, DeviceAttribute> _attributes;
  final List<int> doorOpenReminderValues = <int>[];
  bool flutterConsoleLoggingEnabled = false;
  bool nativeConsoleLoggingEnabled = false;
  SafetyAccessoryPairingStatus safetyAccessoryPairingStatus =
      SafetyAccessoryPairingStatus.success;
  int? safetyAccessoryPairingReasonCode = 0;
  Duration safetyAccessoryPairingDelay = Duration.zero;
  final List<SafetyAccessoryPairingAction> safetyAccessoryPairingActions =
      <SafetyAccessoryPairingAction>[];
  final List<SafetyAccessory> safetyAccessories = <SafetyAccessory>[
    const SafetyAccessory(serialNumber: 0x02000071, statusCode: 0x01),
    const SafetyAccessory(serialNumber: 0x06000072, statusCode: 0x11),
  ];
  bool safetyAccessoryDeleteSucceeds = true;
  int safetyAccessoryDeleteReasonCode = 0;
  Duration safetyAccessoryDeleteDelay = Duration.zero;
  final List<int> deletedSafetyAccessorySerialNumbers = <int>[];
  final Map<String, ConnectedBleDevice> connectedBleDevices =
      <String, ConnectedBleDevice>{};

  static Map<int, DeviceAttribute> _buildAttributes({
    required int autoCloseAttributeId,
    required int autoCloseValue,
  }) {
    final autoCloseWidth = autoCloseAttributeId == 0x2725 ? 2 : 1;
    final autoCloseBytes = Uint8List(autoCloseWidth);
    var remaining = autoCloseValue;
    for (var index = autoCloseBytes.length - 1; index >= 0; index--) {
      autoCloseBytes[index] = remaining & 0xFF;
      remaining >>= 8;
    }
    return <int, DeviceAttribute>{
      0x2711: DeviceAttribute(id: 0x2711, value: Uint8List.fromList([0x07])),
      0x2713: DeviceAttribute(id: 0x2713, value: Uint8List.fromList([0x05])),
      0x2714: DeviceAttribute(id: 0x2714, value: Uint8List.fromList([0x01])),
      autoCloseAttributeId: DeviceAttribute(
        id: autoCloseAttributeId,
        value: autoCloseBytes,
      ),
      0x2726: DeviceAttribute(id: 0x2726, value: Uint8List.fromList([0x05])),
      0x2727: DeviceAttribute(id: 0x2727, value: Uint8List.fromList([0x50])),
    };
  }

  @override
  Stream<BleDevice> get bleScanResults => _scanController.stream;

  @override
  Stream<BleConnectionEvent> get bleConnectionEvents =>
      _connectionController.stream;

  void emitBleConnectionEvent(BleConnectionEvent event) {
    _connectionController.add(event);
  }

  @override
  Stream<BleNotification> get bleNotifications =>
      _notificationController.stream;

  @override
  Stream<NativeHardwareError> get nativeErrors => _nativeErrorController.stream;

  @override
  Stream<BleDiagnosticEvent> get bleDiagnosticEvents =>
      _diagnosticController.stream;

  @override
  Stream<DeviceAttributeSnapshot> get deviceAttributeSnapshots =>
      _attributeController.stream;

  void emitDeviceAttributeSnapshot(DeviceAttributeSnapshot snapshot) {
    _attributeController.add(snapshot);
  }

  @override
  Future<void> configureHardwareLogging({
    required bool flutterConsoleEnabled,
    required bool nativeConsoleEnabled,
  }) async {
    flutterConsoleLoggingEnabled = flutterConsoleEnabled;
    nativeConsoleLoggingEnabled = nativeConsoleEnabled;
  }

  @override
  Future<PermissionSnapshot> getPermissionSnapshot({
    required String requestId,
  }) async {
    return const PermissionSnapshot(
      bluetoothStatus: PermissionStatus.granted,
      cameraStatus: PermissionStatus.granted,
      locationStatus: PermissionStatus.granted,
      microphoneStatus: PermissionStatus.denied,
      storageStatus: PermissionStatus.granted,
      localNetworkGranted: true,
    );
  }

  @override
  Future<PermissionSnapshot> requestPermissions({
    required String requestId,
    required List<PermissionKind> permissions,
  }) async {
    return getPermissionSnapshot(requestId: requestId);
  }

  @override
  Future<PermissionStatus> getNotificationPermission({
    required String requestId,
  }) async {
    return PermissionStatus.granted;
  }

  @override
  Future<PermissionStatus> requestNotificationPermission({
    required String requestId,
  }) async {
    return PermissionStatus.granted;
  }

  @override
  Future<void> openAppSettings({required String requestId}) async {}

  @override
  Future<List<DeviceSummary>> readDevices() async {
    return const <DeviceSummary>[];
  }

  @override
  Future<void> startBleScan({
    required String requestId,
    BleScanFilter filter = const BleScanFilter(),
  }) async {
    final names = filter.exactName != null
        ? <String>[filter.exactName!]
        : filter.namePrefix != null
        ? <String>['${filter.namePrefix}MOCK-SN-001']
        : const <String>['Garage door', 'Test door', 'opener_MOCK-SN-001'];
    for (var index = 0; index < names.length; index += 1) {
      final name = names[index];
      _scanController.add(
        BleDevice(
          requestId: requestId,
          scanSessionId: '$requestId-mock-session',
          id: index == 0 ? 'mock-ble-device' : 'mock-ble-device-$index',
          name: name,
          sn: name,
          rssi: -52 - index,
          seenAtMillis: DateTime.now().millisecondsSinceEpoch,
          advertisementServiceUuids: filter.serviceUuids,
          manufacturerData: Uint8List.fromList(<int>[
            0x46,
            0x4c,
            0x49,
            0x4e,
            0x58,
          ]),
        ),
      );
    }
  }

  @override
  Future<void> stopBleScan({required String requestId}) async {}

  @override
  Future<List<ConnectedBleDevice>> getConnectedBleDevices({
    required String requestId,
  }) async => connectedBleDevices.values.toList(growable: false);

  @override
  Future<List<BleConnectionEvent>> disconnectAllManagedBleDevices({
    required String requestId,
  }) async {
    final events = connectedBleDevices.values
        .map(
          (device) => BleConnectionEvent(
            requestId: requestId,
            deviceId: device.deviceId,
            state: BleConnectionState.disconnected,
          ),
        )
        .toList(growable: false);
    connectedBleDevices.clear();
    for (final event in events) {
      _connectionController.add(event);
    }
    return events;
  }

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
    connectedBleDevices[deviceId] = ConnectedBleDevice(
      deviceId: deviceId,
      state: BleConnectionState.connected,
    );
    return connected;
  }

  @override
  Future<BleAuthenticationResult> authenticateBleDevice({
    required String requestId,
    required String deviceId,
    required String token,
    required String aesKey,
    required String aesKeyVersion,
  }) async {
    return BleAuthenticationResult(
      requestId: requestId,
      deviceId: deviceId,
      authenticated: token.isNotEmpty && aesKey.isNotEmpty,
      bindingState: 0xF1,
      nativeCode: token.isNotEmpty && aesKey.isNotEmpty
          ? null
          : 'mock_missing_credentials',
    );
  }

  @override
  Future<WifiScanResult> scanWifiNetworks({
    required String requestId,
    required String deviceId,
  }) async {
    return WifiScanResult(
      requestId: requestId,
      deviceId: deviceId,
      networks: const <WifiNetwork>[
        WifiNetwork(ssid: 'FLINX Office'),
        WifiNetwork(ssid: 'FLINX Lab 5G'),
        WifiNetwork(ssid: 'Guest WiFi'),
      ],
    );
  }

  @override
  Future<WifiProvisionResult> configureWifi({
    required String requestId,
    required String deviceId,
    required String ssid,
    required String password,
  }) async {
    final skippedWifi = ssid.isEmpty && password.isEmpty;
    final success = skippedWifi || (ssid.isNotEmpty && password.isNotEmpty);
    return WifiProvisionResult(
      requestId: requestId,
      deviceId: deviceId,
      ssid: ssid,
      success: success,
      nativeCode: success ? null : 'mock_invalid_wifi_credentials',
    );
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
    connectedBleDevices.remove(deviceId);
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

  @override
  Future<DeviceAttributeSnapshot> queryDeviceAttributes({
    required String requestId,
    required String deviceId,
  }) async {
    final snapshot = DeviceAttributeSnapshot(
      requestId: requestId,
      deviceId: deviceId,
      sequence: 1,
      timestampMillis: DateTime.now().millisecondsSinceEpoch,
      origin: DeviceAttributeReportOrigin.queryResult,
      attributes: _attributes.values.toList(),
    );
    _attributeController.add(snapshot);
    return snapshot;
  }

  @override
  Future<DeviceAttributeWriteResult> setDeviceAttributes({
    required String requestId,
    required String deviceId,
    required List<DeviceAttribute> attributes,
  }) async {
    for (final attribute in attributes) {
      _attributes[attribute.id] = attribute;
    }
    return DeviceAttributeWriteResult(
      requestId: requestId,
      deviceId: deviceId,
      success: true,
      sequence: 2,
    );
  }

  @override
  Future<CommandResult> setDoorOpenReminder({
    required String requestId,
    required String deviceId,
    required int value,
  }) async {
    final accepted = value == 0 || value == 5 || value == 10 || value == 15;
    if (accepted) {
      doorOpenReminderValues.add(value);
    }
    return CommandResult(
      requestId: requestId,
      deviceId: deviceId,
      accepted: accepted,
      nativeCode:
          'command=0x0E09,data=0x${value.toRadixString(16).padLeft(2, '0').toUpperCase()}',
      domainCode: accepted ? null : 'invalid_door_open_reminder_value',
    );
  }

  @override
  Future<RemotePairingResult> pairRemote({
    required String requestId,
    required String deviceId,
    required RemotePairingAction action,
  }) async {
    return RemotePairingResult(
      requestId: requestId,
      deviceId: deviceId,
      action: action,
      status: RemotePairingStatus.success,
      reasonCode: 0x00000000,
      nativeCode: action == RemotePairingAction.start
          ? 'command=0x0005,responseCommand=0x0104,control=0x1008,result=0x06'
          : 'command=0x0005,responseCommand=0x0104,control=0x1009,result=0x06',
    );
  }

  @override
  Future<SafetyAccessoryPairingResult> pairSafetyAccessory({
    required String requestId,
    required String deviceId,
    required SafetyAccessoryPairingAction action,
  }) async {
    safetyAccessoryPairingActions.add(action);
    if (safetyAccessoryPairingDelay > Duration.zero) {
      await Future<void>.delayed(safetyAccessoryPairingDelay);
    }
    return SafetyAccessoryPairingResult(
      requestId: requestId,
      deviceId: deviceId,
      action: action,
      status: safetyAccessoryPairingStatus,
      reasonCode: safetyAccessoryPairingReasonCode,
      nativeCode: action == SafetyAccessoryPairingAction.start
          ? 'command=0x000B,control=0x100A'
          : 'command=0x000B,control=0x100B',
    );
  }

  @override
  Future<SafetyAccessoryListResult> querySafetyAccessories({
    required String requestId,
    required String deviceId,
  }) async => SafetyAccessoryListResult(
    requestId: requestId,
    deviceId: deviceId,
    totalCount: safetyAccessories.length,
    accessories: List<SafetyAccessory>.unmodifiable(safetyAccessories),
  );

  @override
  Future<SafetyAccessoryDeleteResult> deleteSafetyAccessory({
    required String requestId,
    required String deviceId,
    required int serialNumber,
  }) async {
    if (safetyAccessoryDeleteDelay > Duration.zero) {
      await Future<void>.delayed(safetyAccessoryDeleteDelay);
    }
    if (safetyAccessoryDeleteSucceeds) {
      deletedSafetyAccessorySerialNumbers.add(serialNumber);
      safetyAccessories.removeWhere(
        (accessory) => accessory.serialNumber == serialNumber,
      );
    }
    return SafetyAccessoryDeleteResult(
      requestId: requestId,
      deviceId: deviceId,
      success: safetyAccessoryDeleteSucceeds,
      reasonCode: safetyAccessoryDeleteReasonCode,
      nativeCode: 'command=0x000D',
    );
  }

  @override
  Future<RemoteControlListResult> queryRemotes({
    required String requestId,
    required String deviceId,
  }) async {
    return RemoteControlListResult(
      requestId: requestId,
      deviceId: deviceId,
      totalCount: 2,
      totalPages: 1,
      currentPage: 1,
      hasMore: false,
      remotes: const <RemoteControl>[
        RemoteControl(name: '遥控器1', serialNumber: 0x00000003),
        RemoteControl(name: '遥控器2', serialNumber: 0x00000004),
      ],
    );
  }

  @override
  Future<RemoteOperationResult> deleteRemote({
    required String requestId,
    required String deviceId,
    int? serialNumber,
  }) async {
    return RemoteOperationResult(
      requestId: requestId,
      deviceId: deviceId,
      status: RemoteOperationStatus.success,
      reasonCode: 0x00000000,
      nativeCode: serialNumber == null
          ? 'command=0x0009,type=0xFF'
          : 'command=0x0009,type=0x01',
    );
  }

  @override
  Future<RemoteOperationResult> renameRemote({
    required String requestId,
    required String deviceId,
    required int serialNumber,
    required String name,
  }) async {
    return RemoteOperationResult(
      requestId: requestId,
      deviceId: deviceId,
      status: RemoteOperationStatus.success,
      reasonCode: 0x00000000,
      nativeCode: 'command=0x000A',
    );
  }
}
