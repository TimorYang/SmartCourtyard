import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';

void main() {
  test('emits deterministic BLE scan results', () async {
    final gateway = MockHardwareGateway();
    final scanEvent = expectLater(
      gateway.bleScanResults,
      emits(
        isA<BleDevice>()
            .having((device) => device.id, 'id', 'mock-ble-device')
            .having((device) => device.name, 'name', 'FLINX Mock Device')
            .having((device) => device.requestId, 'requestId', 'scan-1')
            .having(
              (device) => device.scanSessionId,
              'scanSessionId',
              'scan-1-mock-session',
            ),
      ),
    );

    await gateway.startBleScan(requestId: 'scan-1');

    await scanEvent;
  });

  test('emits connection state changes and disconnects', () async {
    final gateway = MockHardwareGateway();
    final connectionEvents = expectLater(
      gateway.bleConnectionEvents,
      emitsInOrder(<Matcher>[
        isA<BleConnectionEvent>().having(
          (event) => event.state,
          'state',
          BleConnectionState.connecting,
        ),
        isA<BleConnectionEvent>().having(
          (event) => event.state,
          'state',
          BleConnectionState.connected,
        ),
        isA<BleConnectionEvent>().having(
          (event) => event.state,
          'state',
          BleConnectionState.disconnected,
        ),
      ]),
    );

    final connected = await gateway.connectBleDevice(
      requestId: 'connect-1',
      deviceId: 'mock-ble-device',
    );
    final disconnected = await gateway.disconnectBleDevice(
      requestId: 'disconnect-1',
      deviceId: 'mock-ble-device',
    );

    expect(connected.state, BleConnectionState.connected);
    expect(disconnected.state, BleConnectionState.disconnected);
    await connectionEvents;
  });

  test('supports ble authentication and wifi provisioning workflow', () async {
    final gateway = MockHardwareGateway();

    final auth = await gateway.authenticateBleDevice(
      requestId: 'auth-1',
      deviceId: 'mock-ble-device',
      token: '0123456789abcdef0123456789abcdef',
    );
    final wifiList = await gateway.scanWifiNetworks(
      requestId: 'wifi-scan-1',
      deviceId: 'mock-ble-device',
    );
    final provision = await gateway.configureWifi(
      requestId: 'wifi-provision-1',
      deviceId: 'mock-ble-device',
      ssid: 'FLINX Office',
      password: '12345678',
    );

    expect(auth.authenticated, isTrue);
    expect(auth.bindingState, 0xF1);
    expect(wifiList.networks.map((network) => network.ssid), isNotEmpty);
    expect(provision.success, isTrue);
    expect(provision.ssid, 'FLINX Office');
  });

  test(
    'supports service discovery, read, write, and notify simulation',
    () async {
      final gateway = MockHardwareGateway();
      final notificationEvent = expectLater(
        gateway.bleNotifications,
        emits(
          isA<BleNotification>()
              .having(
                (notification) => notification.payload.toList(),
                'payload',
                <int>[0x0a],
              )
              .having(
                (notification) => notification.requestId,
                'requestId',
                'write-1',
              ),
        ),
      );

      final services = await gateway.discoverServices(
        requestId: 'services-1',
        deviceId: 'mock-ble-device',
      );
      final read = await gateway.readCharacteristic(
        requestId: 'read-1',
        deviceId: 'mock-ble-device',
        serviceUuid: 'FFF0',
        characteristicUuid: 'FFF1',
      );
      final notify = await gateway.setCharacteristicNotify(
        requestId: 'notify-1',
        deviceId: 'mock-ble-device',
        serviceUuid: 'FFF0',
        characteristicUuid: 'FFF1',
        enabled: true,
      );
      final write = await gateway.writeCharacteristic(
        requestId: 'write-1',
        deviceId: 'mock-ble-device',
        serviceUuid: 'FFF0',
        characteristicUuid: 'FFF1',
        payload: Uint8List.fromList(<int>[0x0a]),
      );

      expect(services.services.single.serviceUuid, 'FFF0');
      expect(read.payload.toList(), <int>[0x01, 0x02]);
      expect(notify.accepted, isTrue);
      expect(write.accepted, isTrue);
      await notificationEvent;
    },
  );

  test('maps native hardware errors into AppError', () {
    final appError = NativeHardwareError(
      code: 'operation_timeout',
      domainCode: AppErrorCode.commandTimeout,
      requestId: 'read-1',
      deviceId: 'mock-ble-device',
      retryable: true,
      timestampMillis: 1,
    ).toAppError();

    expect(appError.code, AppErrorCode.commandTimeout);
    expect(appError.nativeCode, 'operation_timeout');
    expect(appError.requestId, 'read-1');
    expect(appError.deviceId, 'mock-ble-device');
    expect(appError.retryable, isTrue);
    expect(appError.action, AppErrorAction.retry);
  });
}
