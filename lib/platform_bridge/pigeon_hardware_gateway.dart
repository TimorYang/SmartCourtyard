import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/diagnostics/ble_diagnostic_formatter.dart';
import '../core/errors/app_error.dart';
import 'hardware_gateway.dart';
import 'hardware_models.dart';
import 'pigeon/generated/hardware_api.g.dart' as pigeon;

class PigeonHardwareGateway implements HardwareGateway {
  PigeonHardwareGateway({pigeon.HardwareHostApi? hostApi})
    : _hostApi = hostApi ?? pigeon.HardwareHostApi(),
      _flutterApi = _HardwareFlutterApiHandler() {
    pigeon.HardwareFlutterApi.setUp(_flutterApi);
  }

  final pigeon.HardwareHostApi _hostApi;
  final _HardwareFlutterApiHandler _flutterApi;

  @override
  Stream<BleDevice> get bleScanResults => _flutterApi.bleScanResults;

  @override
  Stream<BleConnectionEvent> get bleConnectionEvents =>
      _flutterApi.bleConnectionEvents;

  @override
  Stream<BleNotification> get bleNotifications => _flutterApi.bleNotifications;

  @override
  Stream<NativeHardwareError> get nativeErrors => _flutterApi.nativeErrors;

  @override
  Stream<BleDiagnosticEvent> get bleDiagnosticEvents =>
      _flutterApi.bleDiagnosticEvents;

  @override
  Stream<DeviceAttributeSnapshot> get deviceAttributeSnapshots =>
      _flutterApi.deviceAttributeSnapshots;

  @override
  Future<void> configureHardwareLogging({
    required bool flutterConsoleEnabled,
    required bool nativeConsoleEnabled,
  }) {
    _flutterApi.flutterConsoleEnabled = flutterConsoleEnabled;
    return _mapPigeonCall(
      () => _hostApi.configureHardwareLogging(
        flutterConsoleEnabled,
        nativeConsoleEnabled,
      ),
      requestId: 'hardware-logging-configure',
    );
  }

  @override
  Future<PermissionSnapshot> getPermissionSnapshot({
    required String requestId,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.getPermissionSnapshot(requestId),
      requestId: requestId,
    );
    return dto.toModel();
  }

  @override
  Future<PermissionSnapshot> requestPermissions({
    required String requestId,
    required List<PermissionKind> permissions,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.requestPermissions(
        requestId,
        permissions.map((e) => e.toDto()).toList(),
      ),
      requestId: requestId,
    );
    return dto.toModel();
  }

  @override
  Future<void> openAppSettings({required String requestId}) {
    return _mapPigeonCall(
      () => _hostApi.openAppSettings(requestId),
      requestId: requestId,
    );
  }

  @override
  Future<List<DeviceSummary>> readDevices() async {
    return const <DeviceSummary>[];
  }

  @override
  Future<void> startBleScan({
    required String requestId,
    BleScanFilter filter = const BleScanFilter(),
  }) {
    return _mapPigeonCall(
      () => _hostApi.startBleScan(requestId, filter.toDto()),
      requestId: requestId,
    );
  }

  @override
  Future<void> stopBleScan({required String requestId}) {
    return _mapPigeonCall(
      () => _hostApi.stopBleScan(requestId),
      requestId: requestId,
    );
  }

  @override
  Future<List<ConnectedBleDevice>> getConnectedBleDevices({
    required String requestId,
  }) async {
    final dtos = await _mapPigeonCall(
      () => _hostApi.getConnectedBleDevices(requestId),
      requestId: requestId,
    );
    return dtos.map((dto) => dto.toModel()).toList(growable: false);
  }

  @override
  Future<List<BleConnectionEvent>> disconnectAllManagedBleDevices({
    required String requestId,
  }) async {
    final dtos = await _mapPigeonCall(
      () => _hostApi.disconnectAllManagedBleDevices(requestId),
      requestId: requestId,
    );
    return dtos.map((dto) => dto.toModel()).toList(growable: false);
  }

  @override
  Future<BleConnectionEvent> connectBleDevice({
    required String requestId,
    required String deviceId,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.connectBleDevice(requestId, deviceId),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel();
  }

  @override
  Future<BleAuthenticationResult> authenticateBleDevice({
    required String requestId,
    required String deviceId,
    required String token,
    required String aesKey,
    required String aesKeyVersion,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.authenticateBleDevice(
        requestId,
        deviceId,
        token,
        aesKey,
        aesKeyVersion,
      ),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel();
  }

  @override
  Future<WifiScanResult> scanWifiNetworks({
    required String requestId,
    required String deviceId,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.scanWifiNetworks(requestId, deviceId),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel();
  }

  @override
  Future<WifiProvisionResult> configureWifi({
    required String requestId,
    required String deviceId,
    required String ssid,
    required String password,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.configureWifi(requestId, deviceId, ssid, password),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel();
  }

  @override
  Future<BleConnectionEvent> disconnectBleDevice({
    required String requestId,
    required String deviceId,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.disconnectBleDevice(requestId, deviceId),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel();
  }

  @override
  Future<BleServices> discoverServices({
    required String requestId,
    required String deviceId,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.discoverServices(requestId, deviceId),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel();
  }

  @override
  Future<BleReadResult> readCharacteristic({
    required String requestId,
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.readCharacteristic(
        requestId,
        deviceId,
        serviceUuid,
        characteristicUuid,
      ),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel();
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
    final dto = await _mapPigeonCall(
      () => _hostApi.writeCharacteristic(
        requestId,
        deviceId,
        serviceUuid,
        characteristicUuid,
        payload,
        writeType.toDto(),
      ),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel();
  }

  @override
  Future<BleWriteResult> setCharacteristicNotify({
    required String requestId,
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required bool enabled,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.setCharacteristicNotify(
        requestId,
        deviceId,
        serviceUuid,
        characteristicUuid,
        enabled,
      ),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel();
  }

  @override
  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.sendDoorCommand(requestId, deviceId, command.toDto()),
      requestId: requestId,
      deviceId: deviceId,
    );
    return CommandResult(
      requestId: dto.requestId,
      deviceId: dto.deviceId,
      command: command,
      accepted: dto.accepted,
    );
  }

  @override
  Future<DeviceAttributeSnapshot> queryDeviceAttributes({
    required String requestId,
    required String deviceId,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.queryDeviceAttributes(requestId, deviceId),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel();
  }

  @override
  Future<DeviceAttributeWriteResult> setDeviceAttributes({
    required String requestId,
    required String deviceId,
    required List<DeviceAttribute> attributes,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.setDeviceAttributes(
        requestId,
        deviceId,
        attributes.map((attribute) => attribute.toDto()).toList(),
      ),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel();
  }

  @override
  Future<RemotePairingResult> pairRemote({
    required String requestId,
    required String deviceId,
    required RemotePairingAction action,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.pairRemote(requestId, deviceId, action.toDto()),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel(action);
  }

  @override
  Future<RemoteControlListResult> queryRemotes({
    required String requestId,
    required String deviceId,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.queryRemotes(requestId, deviceId),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel();
  }

  @override
  Future<RemoteOperationResult> deleteRemote({
    required String requestId,
    required String deviceId,
    int? serialNumber,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.deleteRemote(requestId, deviceId, serialNumber),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel();
  }

  @override
  Future<RemoteOperationResult> renameRemote({
    required String requestId,
    required String deviceId,
    required int serialNumber,
    required String name,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.renameRemote(requestId, deviceId, serialNumber, name),
      requestId: requestId,
      deviceId: deviceId,
    );
    return dto.toModel();
  }

  Future<T> _mapPigeonCall<T>(
    FutureOr<T> Function() call, {
    required String requestId,
    String? deviceId,
  }) async {
    try {
      return await Future<T>.sync(call);
    } on PlatformException catch (error) {
      throw _platformExceptionToAppError(
        error,
        requestId: requestId,
        deviceId: deviceId,
      );
    }
  }
}

class _HardwareFlutterApiHandler implements pigeon.HardwareFlutterApi {
  _HardwareFlutterApiHandler()
    : _scanController = StreamController<BleDevice>.broadcast(),
      _connectionController = StreamController<BleConnectionEvent>.broadcast(),
      _notificationController = StreamController<BleNotification>.broadcast(),
      _nativeErrorController =
          StreamController<NativeHardwareError>.broadcast(),
      _diagnosticController = StreamController<BleDiagnosticEvent>.broadcast(),
      _attributeController =
          StreamController<DeviceAttributeSnapshot>.broadcast();

  final StreamController<BleDevice> _scanController;
  final StreamController<BleConnectionEvent> _connectionController;
  final StreamController<BleNotification> _notificationController;
  final StreamController<NativeHardwareError> _nativeErrorController;
  final StreamController<BleDiagnosticEvent> _diagnosticController;
  final StreamController<DeviceAttributeSnapshot> _attributeController;
  final BleDiagnosticFormatter _diagnosticFormatter = BleDiagnosticFormatter();
  bool flutterConsoleEnabled = false;

  Stream<BleDevice> get bleScanResults => _scanController.stream;

  Stream<BleConnectionEvent> get bleConnectionEvents =>
      _connectionController.stream;

  Stream<BleNotification> get bleNotifications =>
      _notificationController.stream;

  Stream<NativeHardwareError> get nativeErrors => _nativeErrorController.stream;

  Stream<BleDiagnosticEvent> get bleDiagnosticEvents =>
      _diagnosticController.stream;

  Stream<DeviceAttributeSnapshot> get deviceAttributeSnapshots =>
      _attributeController.stream;

  @override
  void onBleScanResult(pigeon.BleDeviceDto device) {
    final model = device.toModel();
    _printBleLog(
      'scan_result',
      requestId: model.requestId,
      deviceId: model.id,
      payloadBytes: model.manufacturerData.length,
      details:
          'name=${model.name ?? '(unnamed)'} rssi=${model.rssi} '
          'sn=${model.sn ?? '(missing)'} '
          'services=${model.advertisementServiceUuids.isEmpty ? 'none' : model.advertisementServiceUuids.join(',')} '
          'manufacturer=${_hexString(model.manufacturerData)}',
    );
    _scanController.add(model);
  }

  @override
  void onBleConnectionChanged(pigeon.BleConnectionEventDto event) {
    final model = event.toModel();
    _printBleLog(
      'connection_state',
      requestId: model.requestId,
      deviceId: model.deviceId,
      state: model.state.name,
      nativeCode: model.nativeCode,
    );
    _connectionController.add(model);
  }

  @override
  void onBleNotification(pigeon.BleNotificationDto notification) {
    final model = notification.toModel();
    _notificationController.add(model);
  }

  @override
  void onNativeError(pigeon.NativeErrorDto error) {
    final model = error.toModel();
    _printBleLog(
      'native_error',
      requestId: model.requestId,
      deviceId: model.deviceId,
      nativeCode: model.code,
      details:
          'domain=${model.domainCode} retryable=${model.retryable} '
          'message=${model.message ?? ''}',
    );
    _nativeErrorController.add(model);
  }

  @override
  void onBleDiagnosticEvent(pigeon.BleDiagnosticEventDto event) {
    final model = event.toModel();
    _diagnosticController.add(model);
    if (flutterConsoleEnabled) {
      debugPrint(_diagnosticFormatter.format(model));
    }
  }

  void _printBleLog(
    String operation, {
    String? requestId,
    String? deviceId,
    String? state,
    String? nativeCode,
    int? payloadBytes,
    String? details,
  }) {
    if (!flutterConsoleEnabled) {
      return;
    }
    debugPrint(
      '[BLE] operation=$operation requestId=${requestId ?? '-'} '
      'deviceId=${deviceId ?? '-'} state=${state ?? '-'} '
      'nativeCode=${nativeCode ?? '-'} payloadBytes=${payloadBytes ?? '-'} '
      '${details ?? ''}',
    );
  }

  String _hexString(List<int> bytes) {
    if (bytes.isEmpty) {
      return 'none';
    }
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  @override
  void onDeviceAttributesChanged(pigeon.DeviceAttributeSnapshotDto snapshot) {
    _attributeController.add(snapshot.toModel());
  }
}

extension _DeviceAttributeMapper on DeviceAttribute {
  pigeon.DeviceAttributeDto toDto() {
    return pigeon.DeviceAttributeDto(id: id, value: value);
  }
}

extension _DeviceAttributeDtoMapper on pigeon.DeviceAttributeDto {
  DeviceAttribute toModel() {
    return DeviceAttribute(id: id, value: value);
  }
}

extension _DeviceAttributeSnapshotDtoMapper
    on pigeon.DeviceAttributeSnapshotDto {
  DeviceAttributeSnapshot toModel() {
    return DeviceAttributeSnapshot(
      requestId: requestId,
      deviceId: deviceId,
      sequence: sequence,
      timestampMillis: timestampMillis,
      origin: switch (origin) {
        pigeon.DeviceAttributeReportOriginDto.activeReport =>
          DeviceAttributeReportOrigin.activeReport,
        pigeon.DeviceAttributeReportOriginDto.queryResult =>
          DeviceAttributeReportOrigin.queryResult,
      },
      attributes: attributes.map((attribute) => attribute.toModel()).toList(),
    );
  }
}

extension _DeviceAttributeWriteResultDtoMapper
    on pigeon.DeviceAttributeWriteResultDto {
  DeviceAttributeWriteResult toModel() {
    return DeviceAttributeWriteResult(
      requestId: requestId,
      deviceId: deviceId,
      success: success,
      sequence: sequence,
      reasonCode: reasonCode,
    );
  }
}

extension _BleScanFilterMapper on BleScanFilter {
  pigeon.BleScanFilterDto toDto() {
    return pigeon.BleScanFilterDto(
      serviceUuids: serviceUuids,
      namePrefix: namePrefix,
      exactName: exactName,
      allowDuplicates: allowDuplicates,
    );
  }
}

extension _DoorCommandMapper on DoorCommand {
  pigeon.DoorCommandDto toDto() {
    return switch (this) {
      DoorCommand.open => pigeon.DoorCommandDto.open,
      DoorCommand.stop => pigeon.DoorCommandDto.stop,
      DoorCommand.close => pigeon.DoorCommandDto.close,
      DoorCommand.partialOpen => pigeon.DoorCommandDto.partialOpen,
      DoorCommand.lightOn => pigeon.DoorCommandDto.lightOn,
      DoorCommand.lightOff => pigeon.DoorCommandDto.lightOff,
      DoorCommand.pb => pigeon.DoorCommandDto.pb,
    };
  }
}

extension _RemotePairingActionMapper on RemotePairingAction {
  pigeon.RemotePairingActionDto toDto() {
    return switch (this) {
      RemotePairingAction.start => pigeon.RemotePairingActionDto.start,
      RemotePairingAction.cancel => pigeon.RemotePairingActionDto.cancel,
    };
  }
}

extension _RemotePairingResultMapper on pigeon.RemotePairingResultDto {
  RemotePairingResult toModel(RemotePairingAction action) {
    return RemotePairingResult(
      requestId: requestId,
      deviceId: deviceId,
      action: action,
      status: status.toModel(),
      reasonCode: reasonCode,
      nativeCode: nativeCode,
    );
  }
}

extension _RemotePairingStatusMapper on pigeon.RemotePairingStatusDto {
  RemotePairingStatus toModel() {
    return switch (this) {
      pigeon.RemotePairingStatusDto.success => RemotePairingStatus.success,
      pigeon.RemotePairingStatusDto.failure => RemotePairingStatus.failure,
      pigeon.RemotePairingStatusDto.timeout => RemotePairingStatus.timeout,
      pigeon.RemotePairingStatusDto.unknown => RemotePairingStatus.unknown,
    };
  }
}

extension _RemoteControlListResultMapper on pigeon.RemoteControlListResultDto {
  RemoteControlListResult toModel() {
    return RemoteControlListResult(
      requestId: requestId,
      deviceId: deviceId,
      totalCount: totalCount,
      totalPages: totalPages,
      currentPage: currentPage,
      hasMore: hasMore,
      remotes: remotes.map((remote) => remote.toModel()).toList(),
    );
  }
}

extension _RemoteControlMapper on pigeon.RemoteControlDto {
  RemoteControl toModel() {
    return RemoteControl(name: name, serialNumber: serialNumber);
  }
}

extension _RemoteOperationResultMapper on pigeon.RemoteOperationResultDto {
  RemoteOperationResult toModel() {
    return RemoteOperationResult(
      requestId: requestId,
      deviceId: deviceId,
      status: status.toModel(),
      reasonCode: reasonCode,
      nativeCode: nativeCode,
    );
  }
}

extension _RemoteOperationStatusMapper on pigeon.RemoteOperationStatusDto {
  RemoteOperationStatus toModel() {
    return switch (this) {
      pigeon.RemoteOperationStatusDto.success => RemoteOperationStatus.success,
      pigeon.RemoteOperationStatusDto.failure => RemoteOperationStatus.failure,
      pigeon.RemoteOperationStatusDto.unknown => RemoteOperationStatus.unknown,
    };
  }
}

extension _BleAuthenticationResultMapper on pigeon.BleAuthenticationResultDto {
  BleAuthenticationResult toModel() {
    return BleAuthenticationResult(
      requestId: requestId,
      deviceId: deviceId,
      authenticated: authenticated,
      bindingState: bindingState?.toInt(),
      nativeCode: nativeCode,
    );
  }
}

extension _WifiScanResultMapper on pigeon.WifiScanResultDto {
  WifiScanResult toModel() {
    return WifiScanResult(
      requestId: requestId,
      deviceId: deviceId,
      networks: ssids.map((ssid) => WifiNetwork(ssid: ssid)).toList(),
    );
  }
}

extension _WifiProvisionResultMapper on pigeon.WifiProvisionResultDto {
  WifiProvisionResult toModel() {
    return WifiProvisionResult(
      requestId: requestId,
      deviceId: deviceId,
      ssid: ssid,
      success: success,
      nativeCode: nativeCode,
    );
  }
}

extension _PermissionKindMapper on PermissionKind {
  pigeon.PermissionKindDto toDto() {
    return switch (this) {
      PermissionKind.bluetooth => pigeon.PermissionKindDto.bluetooth,
      PermissionKind.camera => pigeon.PermissionKindDto.camera,
      PermissionKind.location => pigeon.PermissionKindDto.location,
      PermissionKind.microphone => pigeon.PermissionKindDto.microphone,
      PermissionKind.storage => pigeon.PermissionKindDto.storage,
      PermissionKind.localNetwork => pigeon.PermissionKindDto.localNetwork,
      PermissionKind.notification => pigeon.PermissionKindDto.notification,
    };
  }
}

extension _BleWriteTypeMapper on BleWriteType {
  pigeon.BleWriteTypeDto toDto() {
    return switch (this) {
      BleWriteType.withResponse => pigeon.BleWriteTypeDto.withResponse,
      BleWriteType.withoutResponse => pigeon.BleWriteTypeDto.withoutResponse,
    };
  }
}

extension _PermissionSnapshotDtoMapper on pigeon.PermissionSnapshotDto {
  PermissionSnapshot toModel() {
    return PermissionSnapshot(
      bluetoothStatus: bluetoothStatus.toModel(),
      cameraStatus: cameraStatus.toModel(),
      locationStatus: locationStatus.toModel(),
      microphoneStatus: microphoneStatus.toModel(),
      storageStatus: storageStatus.toModel(),
      localNetworkGranted: localNetworkGranted,
      notificationGranted: notificationGranted,
    );
  }
}

extension _PermissionStatusDtoMapper on pigeon.PermissionStatusDto {
  PermissionStatus toModel() {
    return switch (this) {
      pigeon.PermissionStatusDto.granted => PermissionStatus.granted,
      pigeon.PermissionStatusDto.denied => PermissionStatus.denied,
      pigeon.PermissionStatusDto.blocked => PermissionStatus.blocked,
    };
  }
}

extension _BleDeviceDtoMapper on pigeon.BleDeviceDto {
  BleDevice toModel() {
    return BleDevice(
      requestId: requestId,
      scanSessionId: scanSessionId,
      id: id,
      name: name,
      sn: sn,
      rssi: rssi,
      seenAtMillis: seenAtMillis,
      advertisementServiceUuids: advertisementServiceUuids,
      manufacturerData: manufacturerData,
    );
  }
}

extension _BleConnectionEventDtoMapper on pigeon.BleConnectionEventDto {
  BleConnectionEvent toModel() {
    return BleConnectionEvent(
      requestId: requestId,
      deviceId: deviceId,
      state: state.toModel(),
      nativeCode: nativeCode,
    );
  }
}

extension _BleConnectionStateDtoMapper on pigeon.BleConnectionStateDto {
  BleConnectionState toModel() {
    return switch (this) {
      pigeon.BleConnectionStateDto.disconnected =>
        BleConnectionState.disconnected,
      pigeon.BleConnectionStateDto.connecting => BleConnectionState.connecting,
      pigeon.BleConnectionStateDto.connected => BleConnectionState.connected,
    };
  }
}

extension _BleServicesDtoMapper on pigeon.BleServicesDto {
  BleServices toModel() {
    return BleServices(
      requestId: requestId,
      deviceId: deviceId,
      services: services.map((service) => service.toModel()).toList(),
    );
  }
}

extension _BleServiceDtoMapper on pigeon.BleServiceDto {
  BleService toModel() {
    return BleService(
      serviceUuid: serviceUuid,
      characteristics: characteristics
          .map((characteristic) => characteristic.toModel())
          .toList(),
    );
  }
}

extension _BleCharacteristicDtoMapper on pigeon.BleCharacteristicDto {
  BleCharacteristic toModel() {
    return BleCharacteristic(
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      canRead: canRead,
      canWriteWithResponse: canWriteWithResponse,
      canWriteWithoutResponse: canWriteWithoutResponse,
      canNotify: canNotify,
    );
  }
}

extension _BleReadResultDtoMapper on pigeon.BleReadResultDto {
  BleReadResult toModel() {
    return BleReadResult(
      requestId: requestId,
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      payload: payload,
    );
  }
}

extension _BleWriteResultDtoMapper on pigeon.BleWriteResultDto {
  BleWriteResult toModel() {
    return BleWriteResult(
      requestId: requestId,
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      accepted: accepted,
      nativeCode: nativeCode,
    );
  }
}

extension _BleNotificationDtoMapper on pigeon.BleNotificationDto {
  BleNotification toModel() {
    return BleNotification(
      requestId: requestId,
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      payload: payload,
      timestampMillis: timestampMillis,
      sequenceNumber: sequenceNumber,
    );
  }
}

extension _NativeErrorDtoMapper on pigeon.NativeErrorDto {
  NativeHardwareError toModel() {
    return NativeHardwareError(
      code: code,
      domainCode: _parseAppErrorCode(domainCode),
      message: message,
      requestId: requestId,
      deviceId: deviceId,
      retryable: retryable,
      timestampMillis: timestampMillis,
    );
  }
}

extension _BleDiagnosticEventDtoMapper on pigeon.BleDiagnosticEventDto {
  BleDiagnosticEvent toModel() {
    return BleDiagnosticEvent(
      direction: switch (direction) {
        pigeon.BleDiagnosticDirectionDto.tx => BleDiagnosticDirection.tx,
        pigeon.BleDiagnosticDirectionDto.rx => BleDiagnosticDirection.rx,
      },
      timestampMillis: timestampMillis,
      transactionId: transactionId,
      requestId: requestId,
      deviceId: deviceId,
      operation: operation,
      command: command,
      control: control,
      sequence: sequence,
      encryption: encryption,
      originPayload: originPayload,
      encryptedPayload: encryptedPayload,
      decryptedPayload: decryptedPayload,
      packet: packet,
      elapsedMillis: elapsedMillis,
      result: result,
    );
  }
}

extension _ConnectedBleDeviceDtoMapper on pigeon.ConnectedBleDeviceDto {
  ConnectedBleDevice toModel() {
    return ConnectedBleDevice(
      deviceId: deviceId,
      name: name,
      state: state.toModel(),
    );
  }
}

AppError _platformExceptionToAppError(
  PlatformException error, {
  required String requestId,
  String? deviceId,
}) {
  final code = switch (error.code) {
    'bluetooth_unavailable' => AppErrorCode.bluetoothUnavailable,
    'bluetooth_unauthorized' => AppErrorCode.permissionDenied,
    'SecurityException' => AppErrorCode.permissionDenied,
    'permission_denied' => AppErrorCode.permissionDenied,
    'location_services_disabled' => AppErrorCode.permissionDenied,
    'bluetooth_disabled' => AppErrorCode.bluetoothUnavailable,
    'ble_scanner_unavailable' => AppErrorCode.bluetoothUnavailable,
    'peripheral_unavailable' => AppErrorCode.bluetoothDisconnected,
    'operation_in_progress' => AppErrorCode.deviceBusy,
    'operation_timeout' => AppErrorCode.commandTimeout,
    'command_timeout' => AppErrorCode.commandTimeout,
    'provisioning_response_timeout' => AppErrorCode.commandTimeout,
    'remote_pairing_response_timeout' => AppErrorCode.commandTimeout,
    'invalid_remote_pairing_response' => AppErrorCode.pairingFailed,
    'invalid_remote_query_response' => AppErrorCode.pairingFailed,
    'invalid_remote_operation_response' => AppErrorCode.pairingFailed,
    'provisioning_characteristic_not_found' => AppErrorCode.provisioningFailed,
    'encrypted_provisioning_frame_unsupported' =>
      AppErrorCode.provisioningFailed,
    'encrypted_provisioning_frame_decrypt_failed' =>
      AppErrorCode.provisioningFailed,
    'authentication_decrypt_failed' => AppErrorCode.pairingFailed,
    'authentication_failed' => AppErrorCode.pairingFailed,
    'invalid_aes_key' => AppErrorCode.pairingFailed,
    'missing_aes_key' => AppErrorCode.pairingFailed,
    'invalid_auth_response' => AppErrorCode.pairingFailed,
    'invalid_wifi_scan_response' => AppErrorCode.provisioningFailed,
    'invalid_wifi_provision_response' => AppErrorCode.provisioningFailed,
    'bluetooth_disconnected' => AppErrorCode.bluetoothDisconnected,
    _ => AppErrorCode.unknown,
  };
  return AppError(
    code: code,
    messageKey: 'hardware.${error.code}',
    action: _recommendedAction(code),
    nativeCode: error.code,
    requestId: requestId,
    deviceId: deviceId,
    retryable:
        code != AppErrorCode.permissionDenied &&
        code != AppErrorCode.bluetoothUnavailable,
  );
}

AppErrorCode _parseAppErrorCode(String domainCode) {
  return AppErrorCode.values.firstWhere(
    (code) => code.name == domainCode,
    orElse: () => AppErrorCode.unknown,
  );
}

AppErrorAction _recommendedAction(AppErrorCode code) {
  return switch (code) {
    AppErrorCode.permissionDenied => AppErrorAction.openSettings,
    AppErrorCode.bluetoothUnavailable ||
    AppErrorCode.bluetoothDisconnected => AppErrorAction.connectBluetooth,
    AppErrorCode.commandTimeout ||
    AppErrorCode.deviceBusy ||
    AppErrorCode.unknown => AppErrorAction.retry,
    _ => AppErrorAction.none,
  };
}
