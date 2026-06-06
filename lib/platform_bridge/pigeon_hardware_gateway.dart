import 'dart:async';

import 'package:flutter/services.dart';

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
  Future<PermissionSnapshot> getPermissionSnapshot() async {
    final dto = await _mapPigeonCall(
      () => _hostApi.getPermissionSnapshot(),
      requestId: 'permission-snapshot',
    );
    return dto.toModel();
  }

  @override
  Future<PermissionSnapshot> requestPermissions({
    required List<PermissionKind> permissions,
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.requestPermissions(
        permissions.map((e) => e.toDto()).toList(),
      ),
      requestId: 'permission-request',
    );
    return dto.toModel();
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
  }) async {
    final dto = await _mapPigeonCall(
      () => _hostApi.authenticateBleDevice(requestId, deviceId, token),
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
          StreamController<NativeHardwareError>.broadcast();

  final StreamController<BleDevice> _scanController;
  final StreamController<BleConnectionEvent> _connectionController;
  final StreamController<BleNotification> _notificationController;
  final StreamController<NativeHardwareError> _nativeErrorController;

  Stream<BleDevice> get bleScanResults => _scanController.stream;

  Stream<BleConnectionEvent> get bleConnectionEvents =>
      _connectionController.stream;

  Stream<BleNotification> get bleNotifications =>
      _notificationController.stream;

  Stream<NativeHardwareError> get nativeErrors => _nativeErrorController.stream;

  @override
  void onBleScanResult(pigeon.BleDeviceDto device) {
    _scanController.add(device.toModel());
  }

  @override
  void onBleConnectionChanged(pigeon.BleConnectionEventDto event) {
    _connectionController.add(event.toModel());
  }

  @override
  void onBleNotification(pigeon.BleNotificationDto notification) {
    _notificationController.add(notification.toModel());
  }

  @override
  void onNativeError(pigeon.NativeErrorDto error) {
    _nativeErrorController.add(error.toModel());
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
      bluetoothGranted: bluetoothGranted,
      cameraGranted: cameraGranted,
      localNetworkGranted: localNetworkGranted,
      notificationGranted: notificationGranted,
    );
  }
}

extension _BleDeviceDtoMapper on pigeon.BleDeviceDto {
  BleDevice toModel() {
    return BleDevice(
      requestId: requestId,
      scanSessionId: scanSessionId,
      id: id,
      name: name,
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
