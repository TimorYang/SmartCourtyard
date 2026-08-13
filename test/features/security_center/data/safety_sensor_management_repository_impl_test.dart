import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/features/security_center/data/repositories/safety_sensor_management_repository_impl.dart';
import 'package:flinx/features/security_center/domain/entities/safety_sensor_management.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockHardwareGateway gateway;
  late SafetySensorManagementRepositoryImpl repository;

  setUp(() {
    gateway = MockHardwareGateway()
      ..connectedBleDevices['device-1'] = const ConnectedBleDevice(
        deviceId: 'device-1',
        state: BleConnectionState.connected,
      );
    gateway.safetyAccessories
      ..clear()
      ..addAll(const <SafetyAccessory>[
        SafetyAccessory(serialNumber: 0x01000071, statusCode: 0x01),
        SafetyAccessory(serialNumber: 0x02000072, statusCode: 0x00),
        SafetyAccessory(serialNumber: 0x03000073, statusCode: 0x0F),
        SafetyAccessory(serialNumber: 0x04000074, statusCode: 0x02),
        SafetyAccessory(serialNumber: 0x05000075, statusCode: 0x11),
        SafetyAccessory(serialNumber: 0x06000076, statusCode: 0x12),
        SafetyAccessory(serialNumber: 0x7F000077, statusCode: 0x55),
      ]);
    repository = SafetySensorManagementRepositoryImpl(gateway: gateway);
  });

  test('maps types and filters only unmatched accessories', () async {
    final result = await repository.query(
      requestId: 'query-1',
      deviceId: 'device-1',
    );

    expect(result.sensors, hasLength(6));
    expect(
      result.sensors.map((sensor) => sensor.type),
      <SafetySensorManagementType>[
        SafetySensorManagementType.wirelessDoorSensor,
        SafetySensorManagementType.wirelessSlackRope,
        SafetySensorManagementType.wirelessSafetyEdge,
        SafetySensorManagementType.wirelessPhotoBeam,
        SafetySensorManagementType.wirelessElectronicLock,
        SafetySensorManagementType.unknown,
      ],
    );
    expect(result.sensors.last.status, SafetySensorManagementStatus.unknown);
  });

  test('requires the selected BLE device to be connected', () async {
    gateway.connectedBleDevices.clear();

    await expectLater(
      repository.query(requestId: 'query-2', deviceId: 'device-1'),
      throwsA(
        isA<AppError>().having(
          (error) => error.code,
          'code',
          AppErrorCode.bluetoothDisconnected,
        ),
      ),
    );
  });

  test('deletes one serial number and maps device failure', () async {
    await repository.delete(
      requestId: 'delete-1',
      deviceId: 'device-1',
      serialNumber: 0x04000074,
    );
    expect(gateway.deletedSafetyAccessorySerialNumbers, <int>[0x04000074]);

    gateway.safetyAccessoryDeleteSucceeds = false;
    gateway.safetyAccessoryDeleteReasonCode = 0x01020004;
    await expectLater(
      repository.delete(
        requestId: 'delete-2',
        deviceId: 'device-1',
        serialNumber: 0x05000075,
      ),
      throwsA(isA<AppError>()),
    );
  });
}
