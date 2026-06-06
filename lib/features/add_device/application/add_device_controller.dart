import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform_bridge/hardware_gateway.dart';
import '../../../platform_bridge/hardware_models.dart';
import 'providers.dart';

const String addDeviceBleNamePrefix = 'opener_';
const String defaultBleAuthToken = 'AF035A47A6ABB06B884F28409EFB8E44';

class AddDeviceState {
  const AddDeviceState({
    required this.devices,
    required this.connectionStates,
    required this.isScanning,
    required this.isConnecting,
    required this.isAuthenticating,
    required this.isScanningWifi,
    required this.isProvisioningWifi,
    required this.authToken,
    required this.wifiSsid,
    required this.wifiPassword,
    required this.wifiNetworks,
    this.selectedDevice,
    this.errorMessage,
    this.infoMessage,
  });

  factory AddDeviceState.initial() {
    return const AddDeviceState(
      devices: <String, BleDevice>{},
      connectionStates: <String, BleConnectionState>{},
      isScanning: false,
      isConnecting: false,
      isAuthenticating: false,
      isScanningWifi: false,
      isProvisioningWifi: false,
      authToken: String.fromEnvironment(
        'FLINX_BLE_AUTH_TOKEN',
        defaultValue: defaultBleAuthToken,
      ),
      wifiSsid: '',
      wifiPassword: '',
      wifiNetworks: <WifiNetwork>[],
    );
  }

  final Map<String, BleDevice> devices;
  final Map<String, BleConnectionState> connectionStates;
  final bool isScanning;
  final bool isConnecting;
  final bool isAuthenticating;
  final bool isScanningWifi;
  final bool isProvisioningWifi;
  final String authToken;
  final String wifiSsid;
  final String wifiPassword;
  final List<WifiNetwork> wifiNetworks;
  final BleDevice? selectedDevice;
  final String? errorMessage;
  final String? infoMessage;

  List<BleDevice> sortedDevices() {
    final items = devices.values.toList();
    items.sort((a, b) => b.rssi.compareTo(a.rssi));
    return items;
  }

  BleConnectionState connectionStateFor(String deviceId) {
    return connectionStates[deviceId] ?? BleConnectionState.disconnected;
  }

  AddDeviceState copyWith({
    Map<String, BleDevice>? devices,
    Map<String, BleConnectionState>? connectionStates,
    bool? isScanning,
    bool? isConnecting,
    bool? isAuthenticating,
    bool? isScanningWifi,
    bool? isProvisioningWifi,
    String? authToken,
    String? wifiSsid,
    String? wifiPassword,
    List<WifiNetwork>? wifiNetworks,
    BleDevice? selectedDevice,
    bool clearSelectedDevice = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? infoMessage,
    bool clearInfoMessage = false,
  }) {
    return AddDeviceState(
      devices: devices ?? this.devices,
      connectionStates: connectionStates ?? this.connectionStates,
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      isScanningWifi: isScanningWifi ?? this.isScanningWifi,
      isProvisioningWifi: isProvisioningWifi ?? this.isProvisioningWifi,
      authToken: authToken ?? this.authToken,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      wifiNetworks: wifiNetworks ?? this.wifiNetworks,
      selectedDevice: clearSelectedDevice
          ? null
          : selectedDevice ?? this.selectedDevice,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
    );
  }
}

class AddDeviceController extends Notifier<AddDeviceState> {
  late final HardwareGateway _gateway;
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  int _requestCounter = 0;

  @override
  AddDeviceState build() {
    _gateway = ref.watch(addDeviceHardwareGatewayProvider);
    _subscriptions.addAll(<StreamSubscription<Object?>>[
      _gateway.bleScanResults.listen((device) {
        final nextDevices = Map<String, BleDevice>.from(state.devices);
        nextDevices[device.id] = device;
        state = state.copyWith(
          devices: nextDevices,
          clearErrorMessage: true,
          infoMessage: '已发现 ${nextDevices.length} 台蓝牙设备',
        );
      }),
      _gateway.bleConnectionEvents.listen((event) {
        final nextStates = Map<String, BleConnectionState>.from(
          state.connectionStates,
        );
        nextStates[event.deviceId] = event.state;
        state = state.copyWith(connectionStates: nextStates);
      }),
      _gateway.nativeErrors.listen((error) {
        state = state.copyWith(
          errorMessage: error.message ?? error.code,
          infoMessage: null,
        );
      }),
    ]);
    ref.onDispose(() {
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
    });
    return AddDeviceState.initial();
  }

  void updateAuthToken(String value) {
    state = state.copyWith(authToken: value, clearErrorMessage: true);
  }

  void updateWifiSsid(String value) {
    state = state.copyWith(wifiSsid: value, clearErrorMessage: true);
  }

  void updateWifiPassword(String value) {
    state = state.copyWith(wifiPassword: value, clearErrorMessage: true);
  }

  void selectWifiNetwork(String ssid) {
    state = state.copyWith(wifiSsid: ssid, clearErrorMessage: true);
  }

  void clearMessages() {
    state = state.copyWith(clearErrorMessage: true, clearInfoMessage: true);
  }

  Future<void> startScan() async {
    state = state.copyWith(
      isScanning: true,
      clearErrorMessage: true,
      infoMessage: '正在扫描附近蓝牙设备...',
    );
    try {
      await _gateway.startBleScan(
        requestId: _nextRequestId('ble-scan'),
        filter: const BleScanFilter(
          namePrefix: addDeviceBleNamePrefix,
          allowDuplicates: false,
        ),
      );
    } catch (error) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
    }
  }

  Future<void> stopScan() async {
    if (!state.isScanning) {
      return;
    }
    try {
      await _gateway.stopBleScan(requestId: _nextRequestId('ble-stop'));
    } finally {
      state = state.copyWith(isScanning: false, infoMessage: '蓝牙扫描已停止');
    }
  }

  Future<bool> connectAndAuthenticate(BleDevice device) async {
    final token = state.authToken.trim();
    if (token.length != 32) {
      state = state.copyWith(
        errorMessage: '请输入 32 位鉴权 Token（MD5 值）',
        clearInfoMessage: true,
      );
      return false;
    }

    state = state.copyWith(
      selectedDevice: device,
      isConnecting: true,
      isAuthenticating: false,
      clearErrorMessage: true,
      infoMessage: '正在连接 ${device.name ?? device.id} ...',
    );
    try {
      final connectResult = await _gateway.connectBleDevice(
        requestId: _nextRequestId('ble-connect'),
        deviceId: device.id,
      );
      if (connectResult.state != BleConnectionState.connected) {
        state = state.copyWith(
          isConnecting: false,
          errorMessage: '蓝牙连接未成功建立',
          clearInfoMessage: true,
        );
        return false;
      }

      state = state.copyWith(
        isConnecting: false,
        isAuthenticating: true,
        infoMessage: '连接成功，正在鉴权...',
      );
      final authResult = await _gateway.authenticateBleDevice(
        requestId: _nextRequestId('ble-auth'),
        deviceId: device.id,
        token: token,
      );
      if (!authResult.authenticated) {
        state = state.copyWith(
          isAuthenticating: false,
          errorMessage: '鉴权失败，请确认 Token 是否正确',
          clearInfoMessage: true,
        );
        return false;
      }

      state = state.copyWith(
        isAuthenticating: false,
        infoMessage: '鉴权成功，准备配置 Wi‑Fi',
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isConnecting: false,
        isAuthenticating: false,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
      return false;
    }
  }

  Future<List<WifiNetwork>> scanWifiNetworks() async {
    final device = state.selectedDevice;
    if (device == null) {
      state = state.copyWith(errorMessage: '请先连接蓝牙设备');
      return const <WifiNetwork>[];
    }

    state = state.copyWith(
      isScanningWifi: true,
      clearErrorMessage: true,
      infoMessage: '正在扫描设备附近的 Wi‑Fi...',
    );
    try {
      final result = await _gateway.scanWifiNetworks(
        requestId: _nextRequestId('wifi-scan'),
        deviceId: device.id,
      );
      state = state.copyWith(
        isScanningWifi: false,
        wifiNetworks: result.networks,
        infoMessage: '已扫描到 ${result.networks.length} 个 Wi‑Fi',
      );
      return result.networks;
    } catch (error) {
      state = state.copyWith(
        isScanningWifi: false,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
      return const <WifiNetwork>[];
    }
  }

  Future<bool> configureWifi() async {
    final device = state.selectedDevice;
    if (device == null) {
      state = state.copyWith(errorMessage: '请先完成蓝牙连接');
      return false;
    }

    final ssid = state.wifiSsid.trim();
    final password = state.wifiPassword;
    if (ssid.isEmpty) {
      state = state.copyWith(errorMessage: '请选择或输入 Wi‑Fi 名称');
      return false;
    }
    if (password.isEmpty) {
      state = state.copyWith(errorMessage: '请输入 Wi‑Fi 密码');
      return false;
    }

    state = state.copyWith(
      isProvisioningWifi: true,
      clearErrorMessage: true,
      infoMessage: '正在向设备发送 Wi‑Fi 配置...',
    );
    try {
      final result = await _gateway.configureWifi(
        requestId: _nextRequestId('wifi-provision'),
        deviceId: device.id,
        ssid: ssid,
        password: password,
      );
      if (!result.success) {
        state = state.copyWith(
          isProvisioningWifi: false,
          errorMessage: 'Wi‑Fi 配网失败，请重试',
          clearInfoMessage: true,
        );
        return false;
      }

      state = state.copyWith(isProvisioningWifi: false, infoMessage: '设备配网成功');
      return true;
    } catch (error) {
      state = state.copyWith(
        isProvisioningWifi: false,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
      return false;
    }
  }

  String _nextRequestId(String prefix) {
    _requestCounter += 1;
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}-$_requestCounter';
  }
}
