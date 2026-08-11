import 'package:test/test.dart';

import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/features/security_center/data/repositories/safety_sensor_pairing_repository_impl.dart';
import 'package:flinx/features/security_center/domain/entities/safety_sensor_pairing.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';

void main() {
  test('does not send start when the BLE device is disconnected', () async {
    final gateway = MockHardwareGateway();
    final repository = SafetySensorPairingRepositoryImpl(gateway: gateway);

    await expectLater(
      repository.pair(
        const SafetySensorPairingRequest(
          requestId: 'request-1',
          deviceId: 'device-1',
          action: SafetyAccessoryPairingAction.start,
        ),
      ),
      throwsA(
        isA<AppError>().having(
          (error) => error.code,
          'code',
          AppErrorCode.bluetoothDisconnected,
        ),
      ),
    );
    expect(gateway.safetyAccessoryPairingActions, isEmpty);
  });

  test('sends start only after the BLE device is connected', () async {
    final gateway = MockHardwareGateway()
      ..connectedBleDevices['device-1'] = const ConnectedBleDevice(
        deviceId: 'device-1',
        state: BleConnectionState.connected,
      );
    final repository = SafetySensorPairingRepositoryImpl(gateway: gateway);

    final result = await repository.pair(
      const SafetySensorPairingRequest(
        requestId: 'request-2',
        deviceId: 'device-1',
        action: SafetyAccessoryPairingAction.start,
      ),
    );

    expect(result.status, SafetyAccessoryPairingStatus.success);
    expect(gateway.safetyAccessoryPairingActions, [
      SafetyAccessoryPairingAction.start,
    ]);
  });

  test('preserves device failure status and reason code', () async {
    final gateway = MockHardwareGateway()
      ..connectedBleDevices['device-1'] = const ConnectedBleDevice(
        deviceId: 'device-1',
        state: BleConnectionState.connected,
      )
      ..safetyAccessoryPairingStatus = SafetyAccessoryPairingStatus.failure
      ..safetyAccessoryPairingReasonCode = 0x01020004;
    final repository = SafetySensorPairingRepositoryImpl(gateway: gateway);

    final result = await repository.pair(
      const SafetySensorPairingRequest(
        requestId: 'request-3',
        deviceId: 'device-1',
        action: SafetyAccessoryPairingAction.start,
      ),
    );

    expect(result.status, SafetyAccessoryPairingStatus.failure);
    expect(result.reasonCode, 0x01020004);
  });
}
