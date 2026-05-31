import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../platform_bridge/hardware_gateway.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../platform_bridge/providers.dart';

class BleDebugPage extends ConsumerStatefulWidget {
  const BleDebugPage({super.key});

  static const routeName = 'ble-debug';
  static const routePath = '/ble-debug';

  @override
  ConsumerState<BleDebugPage> createState() => _BleDebugPageState();
}

class _BleDebugPageState extends ConsumerState<BleDebugPage> {
  final Map<String, BleDevice> _devices = <String, BleDevice>{};
  final List<String> _log = <String>[];
  final Map<String, BleConnectionState> _connectionStates =
      <String, BleConnectionState>{};
  final Map<String, BleServices> _services = <String, BleServices>{};
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];

  int _requestCounter = 0;
  bool _scanning = false;

  HardwareGateway get _gateway => ref.read(nativeHardwareGatewayProvider);

  @override
  void initState() {
    super.initState();
    final gateway = _gateway;
    _subscriptions.addAll(<StreamSubscription<Object?>>[
      gateway.bleScanResults.listen((device) {
        setState(() {
          _devices[device.id] = device;
          _appendLog('scan: ${device.name ?? '(unnamed)'} ${device.id}');
        });
      }),
      gateway.bleConnectionEvents.listen((event) {
        setState(() {
          _connectionStates[event.deviceId] = event.state;
          _appendLog('connection: ${event.deviceId} ${event.state.name}');
        });
      }),
      gateway.bleNotifications.listen((notification) {
        setState(() {
          _appendLog(
            'notify: ${notification.deviceId} '
            '${notification.serviceUuid}/${notification.characteristicUuid} '
            '${notification.payload.length} bytes',
          );
        });
      }),
      gateway.nativeErrors.listen((error) {
        setState(() {
          _appendLog('error: ${error.code} ${error.message ?? ''}');
        });
      }),
    ]);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = _devices.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    return Scaffold(
      appBar: AppBar(title: const Text('BLE Debug')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Use this page on a physical iPhone. iOS Simulator cannot scan real BLE devices.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _scanning ? null : _startScan,
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('Start scan'),
              ),
              OutlinedButton.icon(
                onPressed: _scanning ? _stopScan : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop scan'),
              ),
              OutlinedButton.icon(
                onPressed: _requestBluetoothPermission,
                icon: const Icon(Icons.privacy_tip_outlined),
                label: const Text('Request permission'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Devices (${devices.length})'),
          const SizedBox(height: 8),
          for (final device in devices)
            _DeviceTile(device: device, state: this),
          const SizedBox(height: 16),
          const Text('Log'),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _log.isEmpty ? 'No events yet.' : _log.reversed.join('\n'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestBluetoothPermission() async {
    try {
      final requestId = _nextRequestId('permission');
      _appendLog('request bluetooth permission: $requestId');
      await _gateway.startBleScan(
        requestId: requestId,
        filter: const BleScanFilter(allowDuplicates: false),
      );
      await _gateway.stopBleScan(requestId: _nextRequestId('stop'));
      setState(() {
        _scanning = false;
        _appendLog('permission request completed');
      });
    } catch (error) {
      setState(() {
        _appendLog('permission request failed: $error');
      });
    }
  }

  Future<void> _startScan() async {
    try {
      setState(() {
        _devices.clear();
        _services.clear();
        _scanning = true;
        _appendLog('start scan');
      });
      await _gateway.startBleScan(
        requestId: _nextRequestId('scan'),
        filter: const BleScanFilter(allowDuplicates: true),
      );
    } catch (error) {
      setState(() {
        _scanning = false;
        _appendLog('start scan failed: $error');
      });
    }
  }

  Future<void> _stopScan() async {
    try {
      await _gateway.stopBleScan(requestId: _nextRequestId('stop'));
      setState(() {
        _scanning = false;
        _appendLog('stop scan');
      });
    } catch (error) {
      setState(() {
        _appendLog('stop scan failed: $error');
      });
    }
  }

  Future<void> _connect(BleDevice device) async {
    try {
      final event = await _gateway.connectBleDevice(
        requestId: _nextRequestId('connect'),
        deviceId: device.id,
      );
      setState(() {
        _connectionStates[device.id] = event.state;
        _appendLog('connect result: ${device.id} ${event.state.name}');
      });
    } catch (error) {
      setState(() {
        _appendLog('connect failed: ${device.id} $error');
      });
    }
  }

  Future<void> _disconnect(BleDevice device) async {
    try {
      final event = await _gateway.disconnectBleDevice(
        requestId: _nextRequestId('disconnect'),
        deviceId: device.id,
      );
      setState(() {
        _connectionStates[device.id] = event.state;
        _appendLog('disconnect result: ${device.id} ${event.state.name}');
      });
    } catch (error) {
      setState(() {
        _appendLog('disconnect failed: ${device.id} $error');
      });
    }
  }

  Future<void> _discoverServices(BleDevice device) async {
    try {
      final services = await _gateway.discoverServices(
        requestId: _nextRequestId('services'),
        deviceId: device.id,
      );
      setState(() {
        _services[device.id] = services;
        _appendLog('services: ${device.id} ${services.services.length}');
      });
    } catch (error) {
      setState(() {
        _appendLog('discover services failed: ${device.id} $error');
      });
    }
  }

  String _nextRequestId(String prefix) {
    _requestCounter += 1;
    return 'debug-$prefix-$_requestCounter';
  }

  void _appendLog(String message) {
    _log.add('${DateTime.now().toIso8601String()}  $message');
    if (_log.length > 80) {
      _log.removeRange(0, _log.length - 80);
    }
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.state});

  final BleDevice device;
  final _BleDebugPageState state;

  @override
  Widget build(BuildContext context) {
    final connectionState =
        state._connectionStates[device.id] ?? BleConnectionState.disconnected;
    final services =
        state._services[device.id]?.services ?? const <BleService>[];
    final connected = connectionState == BleConnectionState.connected;

    return Card(
      child: ExpansionTile(
        title: Text(device.name ?? '(unnamed)'),
        subtitle: Text(
          '${device.id}\nRSSI ${device.rssi}  ${connectionState.name}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: connected ? null : () => state._connect(device),
                child: const Text('Connect'),
              ),
              OutlinedButton(
                onPressed: connected ? () => state._disconnect(device) : null,
                child: const Text('Disconnect'),
              ),
              OutlinedButton(
                onPressed: connected
                    ? () => state._discoverServices(device)
                    : null,
                child: const Text('Discover services'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (services.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('No services discovered yet.'),
            )
          else
            for (final service in services)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${service.serviceUuid}: '
                  '${service.characteristics.map((item) => item.characteristicUuid).join(', ')}',
                ),
              ),
        ],
      ),
    );
  }
}
