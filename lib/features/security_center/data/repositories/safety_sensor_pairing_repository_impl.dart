import '../../../../core/errors/app_error.dart';
import '../../../../platform_bridge/hardware_gateway.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../domain/entities/safety_sensor_pairing.dart';
import '../../domain/repositories/safety_sensor_pairing_repository.dart';

class SafetySensorPairingRepositoryImpl
    implements SafetySensorPairingRepository {
  const SafetySensorPairingRepositoryImpl({required this.gateway});

  final HardwareGateway gateway;

  @override
  Future<bool> isDeviceConnected({
    required String deviceId,
    required String requestId,
  }) async {
    final normalizedDeviceId = deviceId.trim();
    if (normalizedDeviceId.isEmpty) {
      return false;
    }
    final connectedDevices = await gateway.getConnectedBleDevices(
      requestId: requestId,
    );
    return connectedDevices.any(
      (device) =>
          device.deviceId == normalizedDeviceId &&
          device.state == BleConnectionState.connected,
    );
  }

  @override
  Future<SafetySensorPairingResult> pair(
    SafetySensorPairingRequest request,
  ) async {
    final deviceId = request.deviceId.trim();
    if (deviceId.isEmpty) {
      throw AppError(
        code: AppErrorCode.bluetoothDisconnected,
        messageKey: 'safetySensorPairingDeviceMissing',
        action: AppErrorAction.connectBluetooth,
        requestId: request.requestId,
      );
    }

    if (request.action == SafetyAccessoryPairingAction.start) {
      final connected = await isDeviceConnected(
        deviceId: deviceId,
        requestId: '${request.requestId}-connection-check',
      );
      if (!connected) {
        throw AppError(
          code: AppErrorCode.bluetoothDisconnected,
          messageKey: 'safetySensorPairingBluetoothDisconnected',
          action: AppErrorAction.connectBluetooth,
          requestId: request.requestId,
          deviceId: deviceId,
        );
      }
    }

    final result = await gateway.pairSafetyAccessory(
      requestId: request.requestId,
      deviceId: deviceId,
      action: request.action,
    );
    return SafetySensorPairingResult(
      request: request,
      status: result.status,
      reasonCode: result.reasonCode,
      nativeCode: result.nativeCode,
    );
  }
}
