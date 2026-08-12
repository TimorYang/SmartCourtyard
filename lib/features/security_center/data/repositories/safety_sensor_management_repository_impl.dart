import '../../../../core/errors/app_error.dart';
import '../../../../platform_bridge/hardware_gateway.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../domain/entities/safety_sensor_management.dart';
import '../../domain/repositories/safety_sensor_management_repository.dart';

class SafetySensorManagementRepositoryImpl
    implements SafetySensorManagementRepository {
  const SafetySensorManagementRepositoryImpl({required this.gateway});

  final HardwareGateway gateway;

  @override
  Future<SafetySensorManagement> query({
    required String requestId,
    required String deviceId,
  }) async {
    await _ensureConnected(requestId: requestId, deviceId: deviceId);
    final result = await gateway.querySafetyAccessories(
      requestId: requestId,
      deviceId: deviceId,
    );
    return SafetySensorManagement(
      sensors: result.accessories
          .map(_mapAccessory)
          .where(
            (sensor) => sensor.status != SafetySensorManagementStatus.unmatched,
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> delete({
    required String requestId,
    required String deviceId,
    required int serialNumber,
  }) async {
    await _ensureConnected(requestId: requestId, deviceId: deviceId);
    final result = await gateway.deleteSafetyAccessory(
      requestId: requestId,
      deviceId: deviceId,
      serialNumber: serialNumber,
    );
    if (!result.success) {
      throw AppError(
        code: AppErrorCode.unknown,
        messageKey: 'safetySensorManagementDeleteFailed',
        action: AppErrorAction.retry,
        nativeCode: result.nativeCode,
        requestId: requestId,
        deviceId: deviceId,
        retryable: true,
      );
    }
  }

  SafetySensorManagementItem _mapAccessory(
    SafetyAccessory accessory,
  ) => SafetySensorManagementItem(
    serialNumber: accessory.serialNumber,
    type: SafetySensorManagementType.fromSerialNumber(accessory.serialNumber),
    status: SafetySensorManagementStatus.fromProtocolCode(accessory.statusCode),
  );

  Future<void> _ensureConnected({
    required String requestId,
    required String deviceId,
  }) async {
    final normalizedDeviceId = deviceId.trim();
    final devices = normalizedDeviceId.isEmpty
        ? const <ConnectedBleDevice>[]
        : await gateway.getConnectedBleDevices(requestId: requestId);
    final connected = devices.any(
      (device) =>
          device.deviceId == normalizedDeviceId &&
          device.state == BleConnectionState.connected,
    );
    if (!connected) {
      throw AppError(
        code: AppErrorCode.bluetoothDisconnected,
        messageKey: 'safetySensorManagementBluetoothDisconnected',
        action: AppErrorAction.connectBluetooth,
        requestId: requestId,
        deviceId: normalizedDeviceId,
      );
    }
  }
}
